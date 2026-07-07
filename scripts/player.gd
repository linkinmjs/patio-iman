extends CharacterBody3D
## Controlador del jugador a pie: WASD, mouse para cámara, Shift trote, C agacharse.
## Esc libera el mouse; click dentro de la ventana lo vuelve a capturar.

@export_group("Movimiento")
@export var walk_speed := 4.0
@export var sprint_speed := 6.8
@export var crouch_speed := 2.2
@export var acceleration := 10.0
@export var jump_velocity := 4.5

@export_group("Cámara")
@export var mouse_sensitivity := 0.0025

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.2
const STAND_EYE := 1.65
const CROUCH_EYE := 1.05
const HEIGHT_LERP_SPEED := 10.0
const MAX_PITCH := 1.5  # ~86°, evita gimbal en el cenit

@onready var head: Node3D = $Head
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _pitch := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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


func _update_height(crouching: bool, delta: float) -> void:
	var shape: CapsuleShape3D = collision_shape.shape
	var target_height := CROUCH_HEIGHT if crouching else STAND_HEIGHT
	var target_eye := CROUCH_EYE if crouching else STAND_EYE
	shape.height = lerpf(shape.height, target_height, HEIGHT_LERP_SPEED * delta)
	collision_shape.position.y = shape.height * 0.5
	head.position.y = lerpf(head.position.y, target_eye, HEIGHT_LERP_SPEED * delta)
