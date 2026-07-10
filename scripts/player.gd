extends CharacterBody3D
## Controlador del jugador a pie: WASD, mouse para cámara, Shift trote, C agacharse.
## Esc libera el mouse; click dentro de la ventana lo vuelve a capturar.
## Mirando de cerca: E mantenido lootea un auto; E agarra/suelta una parte
## desprendida (se lleva a mano, click izq. la lanza).

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

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.2
const STAND_EYE := 1.65
const CROUCH_EYE := 1.05
const HEIGHT_LERP_SPEED := 10.0
const MAX_PITCH := 1.5  # ~86°, evita gimbal en el cenit

@onready var head: Node3D = $Head
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera: Camera3D = $Head/Camera3D
@onready var prompt: Label = $HUD/Prompt

var _pitch := 0.0
var _carried: RigidBody3D = null
var _loot_target: RigidBody3D = null
var _loot_progress := 0.0


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
			_loot_progress += delta
			prompt.text = "Looteando… %d%%" % int(_loot_progress / loot_time * 100.0)
			if _loot_progress >= loot_time:
				target.loot()
				_loot_progress = 0.0
		else:
			prompt.text = "Lootear — mantener [E]"
	else:
		_loot_target = null
		_loot_progress = 0.0
		prompt.text = ""


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


func _update_height(crouching: bool, delta: float) -> void:
	var shape: CapsuleShape3D = collision_shape.shape
	var target_height := CROUCH_HEIGHT if crouching else STAND_HEIGHT
	var target_eye := CROUCH_EYE if crouching else STAND_EYE
	shape.height = lerpf(shape.height, target_height, HEIGHT_LERP_SPEED * delta)
	collision_shape.position.y = shape.height * 0.5
	head.position.y = lerpf(head.position.y, target_eye, HEIGHT_LERP_SPEED * delta)
