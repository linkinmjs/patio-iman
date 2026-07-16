extends CharacterBody3D
## Controlador del jugador a pie: WASD, mouse para cámara, Shift trote, C agacharse.
## Esc libera el mouse; click dentro de la ventana lo vuelve a capturar.
## Mirando de cerca: E mantenido lootea un auto; E agarra/suelta una parte
## desprendida (se lleva a mano, click izq. la lanza); E lee un cartel
## (el control se congela mientras dura el diálogo).

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
@onready var prompt: Label = $HUD/Prompt

var _pitch := 0.0
var _carried: RigidBody3D = null
var _loot_target: RigidBody3D = null
var _loot_progress := 0.0
var _focusing := false
var _ghost := false
var _normal_mask := 0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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
		prompt.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -MAX_PITCH, MAX_PITCH)
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
