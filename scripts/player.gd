extends CharacterBody3D
## Controlador del jugador a pie: WASD, mouse para cámara, Shift trote, C agacharse.
## Esc libera el mouse; click dentro de la ventana lo vuelve a capturar.
## Mirando de cerca: E mantenido lootea un auto; E agarra/suelta una parte
## desprendida (se lleva a mano, click izq. la lanza); E lee un cartel
## (el control se congela mientras dura el diálogo).
## Con el revólver comprado: G lo saca/guarda, click izq. dispara, click
## der. apunta con miras de hierro (el arma se centra y hay que alinear
## el alza con el guión; el pulso mueve el arma) y R recarga a mano,
## bala por bala.

@export_group("Movimiento")
@export var walk_speed := 4.0
@export var sprint_speed := 6.8
@export var crouch_speed := 2.2
@export var acceleration := 10.0
@export var jump_velocity := 4.5

@export_group("Cámara")
@export var mouse_sensitivity := 0.0025

@export_group("Interacción")
@export var interact_range := 2.8
@export var loot_time := 4.0
@export var carry_offset := Vector3(0, -0.25, -0.85)
@export var throw_speed := 4.5

@export_group("Zoom dramático")
@export var focus_fov := 30.0
@export var focus_in_time := 0.35
@export var focus_out_time := 0.5
@export var focus_time_scale := 0.45  ## cámara lenta durante el zoom

@export_group("Revólver")
@export var cylinder_size := 6
@export var reload_time_per_round := 1.1  ## recarga a mano, bala por bala
@export var gun_cooldown := 0.8
## A: el disparo deja la cámara desviada y la corregís vos.
## B: la cámara devuelve sola casi todo el salto, pero nunca exacto.
@export_enum("A: queda desviado", "B: vuelve con dificultad") var recoil_style := 0
@export var gun_recoil_deg := Vector2(2.5, 5.0)  ## patada de cámara mín/máx
@export var recoil_recover_speed := 7.0  ## estilo B: fracción devuelta por segundo
@export var hip_spread_deg := 5.0  ## dispersión sin apuntar
@export var aim_spread_deg := 0.15  ## apuntando, la bala va adonde miran las miras
@export var aim_sway_deg := 0.8  ## temblor del arma al apuntar (pulso de novato)
@export var aim_fov := 65.0
## Posición del arma apuntando: la línea alza-guión coincide con el ojo.
@export var ads_position := Vector3(0.0, -0.06, -0.35)
@export var gun_impulse := 9.0
@export var gun_range := 60.0

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.2
const STAND_EYE := 1.65
const CROUCH_EYE := 1.05
const HEIGHT_LERP_SPEED := 10.0
const MAX_PITCH := 1.5  # ~86°, evita gimbal en el cenit

@onready var head: Node3D = $Head
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Linterna
@onready var gun_visual: Node3D = $Head/Camera3D/Revolver
@onready var gun_flash: OmniLight3D = $Head/Camera3D/Revolver/Flash
@onready var prompt: Label = $HUD/Prompt
@onready var ammo_label: Label = $HUD/Balas

var _pitch := 0.0
var _carried: RigidBody3D = null
var _loot_target: RigidBody3D = null
var _loot_progress := 0.0
var _focusing := false
var _ghost := false
var _normal_mask := 0
var _gun_out := false
var _gun_cool := 0.0
var _cylinder := 0  # balas en el tambor
var _reloading := false
var _reload_left := 0.0
var _aim := false
var _aim_wander := Vector2.ZERO  # temblor del arma (rad): x yaw, y pitch
var _wander_time := 0.0
var _recoil_left := Vector2.ZERO  # retroceso pendiente de devolver (estilo B)
var _fov_normal := 80.0
var _hip_pos := Vector3.ZERO  # posición del arma al costado (de la escena)
var _gun_kick := 0.0  # culatazo visual pendiente de decaer


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_fov_normal = camera.fov
	_hip_pos = gun_visual.position


## Habilita/deshabilita el control del jugador (p. ej. al entrar al modo grúa).
func set_control_enabled(enabled: bool) -> void:
	set_physics_process(enabled)
	set_process_unhandled_input(enabled)
	if enabled:
		camera.current = true
	else:
		if _carried:
			_drop(0.0)
		_loot_target = null
		_loot_progress = 0.0
		_aim = false
		prompt.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := mouse_sensitivity * (0.55 if _aim else 1.0)  # apuntar afina el pulso
		rotate_y(-event.relative.x * sens)
		_pitch = clampf(_pitch - event.relative.y * sens, -MAX_PITCH, MAX_PITCH)
		head.rotation.x = _pitch
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if _ghost:
		_ghost_move()
		return
	if Input.is_action_just_pressed("flashlight") \
			and GameState.effect("has_flashlight", 0.0) > 0.0:
		flashlight.visible = not flashlight.visible
	if Input.is_action_just_pressed("gun_toggle") \
			and GameState.upgrade_level("revolver") > 0:
		_set_gun_out(not _gun_out)

	var crouching := Input.is_action_pressed("crouch")
	_update_height(crouching, delta)

	if not is_on_floor():
		velocity += get_gravity() * delta
	elif Input.is_action_just_pressed("jump") and not crouching:
		velocity.y = jump_velocity

	var speed := crouch_speed if crouching \
			else (sprint_speed if Input.is_action_pressed("sprint") else walk_speed)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	velocity.x = lerpf(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = lerpf(velocity.z, direction.z * speed, acceleration * delta)

	move_and_slide()
	_update_interaction(delta)
	if _gun_out:
		_update_gun(delta)


## Looteo y acarreo: raycast corto desde la cámara decide el objetivo.
func _update_interaction(delta: float) -> void:
	if _carried:
		_hold_carried()
		prompt.text = "E — soltar · Click izq. — lanzar"
		if Input.is_action_just_pressed("interact"):
			_drop(1.0)
		elif Input.is_action_just_pressed("magnet_toggle"):
			_drop(throw_speed)
		return

	var target = _aim_target()
	if target is RigidBody3D and target.is_in_group("parte") and not target.freeze:
		_loot_target = null
		_loot_progress = 0.0
		prompt.text = "Agarrar [E]"
		if Input.is_action_just_pressed("interact"):
			_pick_up(target)
	elif target is RigidBody3D and target.is_in_group("auto") \
			and not target.freeze and not target.looted:
		if target != _loot_target:
			_loot_target = target
			_loot_progress = 0.0
		if Input.is_action_pressed("interact"):
			var effective_loot_time: float = GameState.effect("loot_time", loot_time)
			_loot_progress += delta
			prompt.text = "Looteando… %d%%" % int(_loot_progress / effective_loot_time * 100.0)
			if _loot_progress >= effective_loot_time:
				target.loot()
				_loot_progress = 0.0
		else:
			prompt.text = "Lootear — mantener [E]"
	elif target is RigidBody3D and target.is_in_group("trofeo"):
		_loot_target = null
		_loot_progress = 0.0
		prompt.text = "Guardar trofeo [E]"
		if Input.is_action_just_pressed("interact"):
			GameState.collect_trophy(str(target.get_meta("trophy_id", "trofeo")),
					str(target.get_meta("trophy_name", "Trofeo")))
			target.queue_free()
	elif target is StaticBody3D and target.is_in_group("cartel"):
		_loot_target = null
		_loot_progress = 0.0
		prompt.text = "Leer [E]"
		if Input.is_action_just_pressed("interact"):
			_start_dialogue(target)
	else:
		_loot_target = null
		_loot_progress = 0.0
		prompt.text = ""


## Muestra un diálogo congelando el control y liberando el mouse; el control
## vuelve solo cuando el diálogo termina.
func play_dialogue(resource: DialogueResource, title := "start") -> void:
	set_control_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)
	DialogueManager.show_dialogue_balloon(resource, title)


func _start_dialogue(sign_body) -> void:
	play_dialogue(sign_body.dialogue, sign_body.dialogue_title)


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_control_enabled(true)


## Zoom dramático (estilo Grunn) hacia un punto de interés: congela el
## control, gira la vista hacia el punto, cierra el FOV y ralentiza el
## tiempo; al terminar devuelve el control con la mirada sobre el evento.
## Cualquier sistema puede dispararlo sobre el nodo del grupo "player".
func focus_on(point: Vector3, hold := 1.4) -> void:
	if _focusing:
		return
	_focusing = true
	set_control_enabled(false)
	Engine.time_scale = focus_time_scale
	var base_fov := camera.fov
	var to_point := point - head.global_position
	var start_yaw := rotation.y
	var start_pitch := head.rotation.x
	var target_yaw := atan2(-to_point.x, -to_point.z)
	var target_pitch := clampf(
			atan2(to_point.y, Vector2(to_point.x, to_point.z).length()),
			-MAX_PITCH, MAX_PITCH)

	var look := func(t: float) -> void:
		rotation.y = lerp_angle(start_yaw, target_yaw, t)
		head.rotation.x = lerp_angle(start_pitch, target_pitch, t)
	var tw := create_tween().set_parallel(true)
	tw.set_speed_scale(1.0 / focus_time_scale)  # el zoom no se ralentiza a sí mismo
	tw.tween_method(look, 0.0, 1.0, focus_in_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(camera, "fov", focus_fov, focus_in_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	await get_tree().create_timer(hold, true, false, true).timeout

	Engine.time_scale = 1.0
	var back := create_tween()
	back.tween_property(camera, "fov", base_fov, focus_out_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await back.finished
	_pitch = head.rotation.x
	_focusing = false
	set_control_enabled(true)


func _aim_target():  # Object o null; sin tipo para acceder a props de scripts
	var from := camera.global_position
	var to := from - camera.global_basis.z * interact_range
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("collider")


func _pick_up(part: RigidBody3D) -> void:
	if _gun_out:
		_set_gun_out(false)  # las dos manos van a la parte
	_carried = part
	part.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	part.freeze = true
	# Sin colisión mientras se lleva, para que no empuje al player.
	part.collision_layer = 0
	part.collision_mask = 0
	_hold_carried()


func _hold_carried() -> void:
	_carried.global_transform = Transform3D(
			Basis(Vector3.UP, rotation.y),
			head.global_position + head.global_basis * carry_offset)


func _drop(speed: float) -> void:
	var part := _carried
	_carried = null
	part.collision_layer = 1
	part.collision_mask = 3
	part.freeze = false
	part.sleeping = false
	part.linear_velocity = velocity - head.global_basis.z * speed
	part.angular_velocity = Vector3.ZERO


func _set_gun_out(out: bool) -> void:
	_gun_out = out
	gun_visual.visible = out
	ammo_label.visible = out
	if not out:
		_reloading = false
		_aim = false
		_aim_wander = Vector2.ZERO
		_recoil_left = Vector2.ZERO
		_gun_kick = 0.0
		gun_visual.position = _hip_pos
		gun_visual.rotation = Vector3.ZERO
		camera.fov = _fov_normal
	_refresh_ammo()


func _refresh_ammo() -> void:
	if _cylinder <= 0 and GameState.ammo <= 0:
		ammo_label.text = "Sin balas — la tienda vende cajas"
	elif _cylinder <= 0:
		ammo_label.text = "Tambor vacío — R recarga (reserva %d)" % GameState.ammo
	else:
		ammo_label.text = "Tambor %d/%d · Reserva %d" \
				% [_cylinder, cylinder_size, GameState.ammo]


## Toda la lógica del revólver en mano: apuntado con deriva, recarga bala
## por bala, recuperación del retroceso (estilo B) y el gatillo.
func _update_gun(delta: float) -> void:
	_gun_cool = maxf(_gun_cool - delta, 0.0)

	# Estilo B: la cámara devuelve el salto de a poco (el mouse manda igual,
	# porque se descuenta una cantidad fija, no hacia una orientación).
	if _recoil_left != Vector2.ZERO:
		var give := _recoil_left * minf(recoil_recover_speed * delta, 1.0)
		_pitch = clampf(_pitch - give.y, -MAX_PITCH, MAX_PITCH)
		head.rotation.x = _pitch
		rotate_y(-give.x)
		_recoil_left -= give
		if _recoil_left.length() < 0.0005:
			_recoil_left = Vector2.ZERO

	# Apuntado (mantener click der.): el arma se centra y se mira a través
	# de las miras de hierro. El pulso rota el arma entera — el guión se
	# desalinea del alza a la vista — y la bala sale adonde apunta el cañón.
	var aiming := Input.is_action_pressed("precision") and not _reloading
	if aiming and not _aim:
		_wander_time = randf() * 20.0  # fase distinta en cada apuntada
	_aim = aiming
	camera.fov = lerpf(camera.fov, aim_fov if _aim else _fov_normal, 10.0 * delta)
	if _aim:
		_wander_time += delta
		var amp := deg_to_rad(aim_sway_deg)
		if velocity.length() > 0.5:
			amp *= 1.6  # caminar empeora el pulso
		elif Input.is_action_pressed("crouch"):
			amp *= 0.65  # agachado, algo más firme
		_aim_wander = Vector2(
				sin(_wander_time * 1.7) * 0.6 + sin(_wander_time * 2.9 + 1.3) * 0.4,
				(sin(_wander_time * 2.3 + 0.7) * 0.55 + sin(_wander_time * 3.7) * 0.45) * 0.8) * amp
	else:
		_aim_wander = _aim_wander.lerp(Vector2.ZERO, 12.0 * delta)
	_update_gun_pose(delta)

	# Recarga a mano, una bala por vez; un click cierra el tambor antes.
	if _reloading:
		if Input.is_action_just_pressed("magnet_toggle") and _cylinder > 0:
			_end_reload()
			return
		_reload_left -= delta
		ammo_label.text = "Recargando… %d/%d (reserva %d)" \
				% [_cylinder, cylinder_size, GameState.ammo]
		if _reload_left <= 0.0:
			_cylinder += 1
			GameState.ammo -= 1
			if _cylinder >= cylinder_size or GameState.ammo <= 0:
				_end_reload()
			else:
				_reload_left = reload_time_per_round
		return
	if Input.is_action_just_pressed("reload") \
			and _cylinder < cylinder_size and GameState.ammo > 0:
		_start_reload()
		return

	if _carried == null and _gun_cool == 0.0 \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED \
			and Input.is_action_just_pressed("magnet_toggle"):
		_fire()


func _start_reload() -> void:
	_reloading = true
	_reload_left = reload_time_per_round


func _end_reload() -> void:
	_reloading = false
	_refresh_ammo()


## Acomoda el arma: centrada frente al ojo al apuntar (el temblor la rota
## y desalinea las miras), al costado si no, inclinada con el tambor
## abierto. El culatazo la empuja hacia atrás y decae solo.
func _update_gun_pose(delta: float) -> void:
	_gun_kick = maxf(_gun_kick - 0.4 * delta, 0.0)
	var target_pos := (ads_position if _aim else _hip_pos) + Vector3(0, 0, _gun_kick)
	gun_visual.position = gun_visual.position.lerp(target_pos, 14.0 * delta)
	var target_rot := Vector3.ZERO
	if _reloading:
		target_rot.x = -0.5  # tambor abierto
	elif _aim:
		target_rot = Vector3(_aim_wander.y, _aim_wander.x, 0.0)
	gun_visual.rotation = gun_visual.rotation.lerp(target_rot, 18.0 * delta)


## Un tiro del revólver: dispersión y retroceso de novato (el operario no
## tiene entrenamiento). El impacto solo empuja física; contra cualquier
## otra cosa el arma no hace nada — es un placebo de control (prompt-lore).
func _fire() -> void:
	_gun_cool = gun_cooldown
	if _cylinder <= 0:
		_refresh_ammo()
		return  # click seco
	_cylinder -= 1
	_refresh_ammo()
	var spread := deg_to_rad(aim_spread_deg if _aim else hip_spread_deg)
	# Apuntando, la bala sale adonde apunta el cañón (miras incluidas,
	# temblor incluido); de cadera, hacia el frente con dispersión grande.
	var dir: Vector3 = -gun_visual.global_basis.z if _aim else -camera.global_basis.z
	dir = dir \
			.rotated(camera.global_basis.x, randf_range(-spread, spread)) \
			.rotated(camera.global_basis.y, randf_range(-spread, spread))
	var query := PhysicsRayQueryParameters3D.create(camera.global_position,
			camera.global_position + dir * gun_range, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var body = hit["collider"]
		if body is RigidBody3D and not body.freeze:
			var impact: Vector3 = hit["position"]
			body.apply_impulse(dir * gun_impulse, impact - body.global_position)
			body.sleeping = false
		# Hook genérico: cualquier cosa baleable declara on_shot() (OVNI,
		# futuros blancos con puntaje) sin acoplarse al player.
		if body != null and body.has_method("on_shot"):
			body.on_shot()
	# Retroceso: salto de cámara; en estilo B casi todo se devuelve solo.
	var kick := Vector2(deg_to_rad(randf_range(-1.5, 1.5)),
			deg_to_rad(randf_range(gun_recoil_deg.x, gun_recoil_deg.y)))
	_pitch = clampf(_pitch + kick.y, -MAX_PITCH, MAX_PITCH)
	head.rotation.x = _pitch
	rotate_y(kick.x)
	if recoil_style == 1:
		_recoil_left += kick * randf_range(0.8, 0.95)
	gun_flash.visible = true
	_gun_kick = 0.09  # culatazo visual: decae solo en _update_gun_pose
	get_tree().create_timer(0.07).timeout.connect(func() -> void:
		gun_flash.visible = false)


## Modo fantasma del menú de debug: vuelo libre sin colisiones.
func set_ghost_mode(on: bool) -> void:
	_ghost = on
	if on and _normal_mask == 0:
		_normal_mask = collision_mask
	collision_mask = 0 if on else _normal_mask
	velocity = Vector3.ZERO
	prompt.text = ""


## WASD en la dirección de la mirada, Space sube, C baja, Shift acelera.
func _ghost_move() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir: Vector3 = head.global_basis * Vector3(input_dir.x, 0.0, input_dir.y)
	dir.y += Input.get_axis("crouch", "jump")
	var speed := sprint_speed * (3.0 if Input.is_action_pressed("sprint") else 1.5)
	velocity = dir.limit_length(1.0) * speed
	move_and_slide()


func _update_height(crouching: bool, delta: float) -> void:
	var shape: CapsuleShape3D = collision_shape.shape
	var target_height := CROUCH_HEIGHT if crouching else STAND_HEIGHT
	var target_eye := CROUCH_EYE if crouching else STAND_EYE
	shape.height = lerpf(shape.height, target_height, HEIGHT_LERP_SPEED * delta)
	collision_shape.position.y = shape.height * 0.5
	head.position.y = lerpf(head.position.y, target_eye, HEIGHT_LERP_SPEED * delta)
