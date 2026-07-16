extends CharacterBody3D
## Grúa móvil tipo tractor (material handler). El jugador se sube con E.
## Se maneja en primera persona desde la cabina: W/S avanza/retrocede (muy
## lento), A/D gira el vehículo, la torreta persigue lentamente hacia donde
## mira el operador, Q/E baja/sube el brazo, Z/X rota el auto colgado,
## RMB precisión, Tab para bajarse. Al avanzar empuja autos como un tanque.

@export_group("Manejo")
@export var drive_speed := 2.5
@export var reverse_speed := 1.5
@export var turn_speed := 0.35
@export var acceleration := 2.0
@export var precision_factor := 0.4
@export var push_accel := 14.0  # m/s² aplicados a un auto al arrollarlo

@export_group("Brazo")
@export var boom_speed := 0.5
@export var boom_pitch_range := Vector2(0.3, 1.2)
@export var turret_follow_speed := 0.5

@export_group("Cámara")
@export var mouse_sensitivity := 0.0025
@export var head_yaw_limit := 2.6

@onready var turret: Node3D = $Torreta
@onready var boom_pivot: Node3D = $Torreta/BoomPivot
@onready var hanging: Node3D = $Torreta/BoomPivot/Codo/Punta/HangingMagnet
@onready var cam_yaw: Node3D = $Torreta/CamYaw
@onready var cam_pitch: Node3D = $Torreta/CamYaw/CamPitch
@onready var camera: Camera3D = $Torreta/CamYaw/CamPitch/Camera3D
@onready var board_area: Area3D = $Acceso/Area3D
@onready var board_label: Label3D = $Acceso/Label3D
@onready var exit_point: Marker3D = $Acceso/PuntoBajada
@onready var hud: CanvasLayer = $HUD

var active := false

var _player: Node3D = null
var _player_near := false
var _speed := 0.0


func _ready() -> void:
	board_area.body_entered.connect(_on_board_body_entered)
	board_area.body_exited.connect(_on_board_body_exited)
	board_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam_yaw.rotation.y = clampf(
				cam_yaw.rotation.y - event.relative.x * mouse_sensitivity,
				-head_yaw_limit, head_yaw_limit)
		cam_pitch.rotation.x = clampf(
				cam_pitch.rotation.x - event.relative.y * mouse_sensitivity, -1.0, 0.6)
	elif event is InputEventMouseButton:
		if event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if active:
		_process_controls(delta)
	else:
		_speed = lerpf(_speed, 0.0, acceleration * delta)
		if _player_near and Input.is_action_just_pressed("interact"):
			_enter()

	var forward := -transform.basis.z
	velocity.x = forward.x * _speed
	velocity.z = forward.z * _speed
	move_and_slide()
	_push_cars()


func _process_controls(delta: float) -> void:
	if Input.is_action_just_pressed("exit_mode"):
		_exit()
		return

	if Input.is_action_just_pressed("magnet_toggle"):
		hanging.toggle_magnet()
	elif Input.is_action_just_pressed("magnet_release"):
		hanging.release()

	var factor := precision_factor if Input.is_action_pressed("precision") else 1.0

	var throttle := Input.get_axis("move_back", "move_forward")
	var steer := Input.get_axis("move_left", "move_right")
	var max_speed := (drive_speed if throttle >= 0.0 else reverse_speed) \
			* GameState.effect("tractor_speed_mult", 1.0)
	_speed = lerpf(_speed, throttle * max_speed * factor, acceleration * delta)
	rotate_y(-steer * turn_speed * factor * delta)

	var boom_axis := Input.get_axis("crane_down", "crane_up")
	boom_pivot.rotation.x = clampf(
			boom_pivot.rotation.x + boom_axis * boom_speed * factor * delta,
			boom_pitch_range.x, boom_pitch_range.y)

	var spin := Input.get_axis("magnet_rotate_right", "magnet_rotate_left")
	if spin != 0.0:
		hanging.rotate_carried(spin * factor, delta)

	# La torreta persigue la mirada del operador: gira hacia donde apunta la
	# cabeza y la cabeza compensa, así la vista queda fija mientras la torreta
	# se acomoda debajo con su propia velocidad.
	var head_offset := cam_yaw.rotation.y
	var step := clampf(head_offset,
			-turret_follow_speed * factor * delta, turret_follow_speed * factor * delta)
	turret.rotate_y(step)
	cam_yaw.rotation.y -= step


# move_and_slide no transfiere fuerza a los RigidBody: sin esto la grúa se
# frena en seco contra un auto de frente en vez de empujarlo como un tanque.
func _push_cars() -> void:
	var strength := absf(_speed) / drive_speed
	if strength < 0.05:
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var body := col.get_collider() as RigidBody3D
		if body == null or body.freeze:
			continue
		var dir := -col.get_normal()
		dir.y = 0.0
		if dir.length_squared() < 0.01:
			continue
		body.apply_force(dir.normalized() * push_accel * strength * body.mass,
				col.get_position() - body.global_position)


func _enter() -> void:
	active = true
	board_label.visible = false
	hud.visible = true
	_player.set_control_enabled(false)
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _exit() -> void:
	active = false
	hud.visible = false
	_player.global_position = exit_point.global_position
	_player.velocity = Vector3.ZERO
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_player.set_control_enabled(true)
	board_label.visible = _player_near


func _on_board_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player = body
		_player_near = true
		if not active:
			board_label.visible = true


func _on_board_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		board_label.visible = false
