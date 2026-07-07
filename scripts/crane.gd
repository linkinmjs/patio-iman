extends Node3D
## Grúa pórtico del patio. Se opera desde la consola (E).
## En modo grúa: WASD mueve puente (W/S) y carro (A/D), Q/E baja/sube el imán,
## RMB modo precisión, rueda del mouse zoom, Tab vuelve al modo a pie.

@export_group("Velocidades")
@export var bridge_speed := 6.0
@export var trolley_speed := 6.0
@export var hoist_speed := 3.0
@export var acceleration := 3.0
@export var precision_factor := 0.4

@export_group("Límites")
@export var trolley_x_range := Vector2(-12.0, 12.0)
@export var bridge_z_range := Vector2(-22.0, 22.0)
@export var hoist_y_range := Vector2(-6.9, -0.8)

@export_group("Cámara")
@export var mouse_sensitivity := 0.0025
@export var zoom_range := Vector2(4.0, 14.0)

@onready var bridge: Node3D = $Puente
@onready var trolley: Node3D = $Puente/Carro
@onready var magnet: Node3D = $Puente/Carro/Iman
@onready var cable: CSGCylinder3D = $Puente/Carro/Cable
@onready var cam_yaw: Node3D = $Puente/Carro/CamYaw
@onready var cam_pitch: Node3D = $Puente/Carro/CamYaw/CamPitch
@onready var camera: Camera3D = $Puente/Carro/CamYaw/CamPitch/Camera3D
@onready var console_area: Area3D = $Consola/Area3D
@onready var console_label: Label3D = $Consola/Label3D
@onready var hud: CanvasLayer = $HUD

var active := false

var _player: Node3D = null
var _player_near := false
var _velocity := Vector3.ZERO  # x = carro, y = imán, z = puente
var _zoom := 9.0


func _ready() -> void:
	console_area.body_entered.connect(_on_console_body_entered)
	console_area.body_exited.connect(_on_console_body_exited)
	console_label.visible = false
	_update_cable()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam_yaw.rotate_y(-event.relative.x * mouse_sensitivity)
		cam_pitch.rotation.x = clampf(
				cam_pitch.rotation.x - event.relative.y * mouse_sensitivity, -1.4, 0.4)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = maxf(_zoom - 1.0, zoom_range.x)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = minf(_zoom + 1.0, zoom_range.y)
		elif event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	if active:
		_process_controls(delta)
	elif _player_near and Input.is_action_just_pressed("interact"):
		_enter()


func _process_controls(delta: float) -> void:
	if Input.is_action_just_pressed("exit_mode"):
		_exit()
		return

	var factor := precision_factor if Input.is_action_pressed("precision") else 1.0
	var target := Vector3(
			Input.get_axis("move_left", "move_right") * trolley_speed,
			Input.get_axis("crane_down", "crane_up") * hoist_speed,
			Input.get_axis("move_forward", "move_back") * bridge_speed) * factor
	_velocity = _velocity.lerp(target, acceleration * delta)

	trolley.position.x = clampf(
			trolley.position.x + _velocity.x * delta, trolley_x_range.x, trolley_x_range.y)
	magnet.position.y = clampf(
			magnet.position.y + _velocity.y * delta, hoist_y_range.x, hoist_y_range.y)
	bridge.position.z = clampf(
			bridge.position.z + _velocity.z * delta, bridge_z_range.x, bridge_z_range.y)

	camera.position.z = lerpf(camera.position.z, _zoom, 8.0 * delta)
	_update_cable()


func _update_cable() -> void:
	var length := absf(magnet.position.y)
	cable.height = length
	cable.position.y = -length * 0.5


func _enter() -> void:
	active = true
	console_label.visible = false
	hud.visible = true
	_velocity = Vector3.ZERO
	_player.set_control_enabled(false)
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _exit() -> void:
	active = false
	console_label.visible = _player_near
	hud.visible = false
	_player.set_control_enabled(true)


func _on_console_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player = body
		_player_near = true
		if not active:
			console_label.visible = true


func _on_console_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		console_label.visible = false
