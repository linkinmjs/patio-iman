extends Node3D
## Grúa pórtico del patio. Se opera desde la consola (E) SIN cambiar de
## cámara: el operario queda parado frente al monitor de la consola, que
## muestra una vista cenital desde el carro (donde nace el cable del imán).
## En modo grúa: W/S mueve el puente, A/D el carro, Q/E baja/sube el imán,
## Z/X rota el auto colgado, RMB precisión, rueda zoom del monitor,
## Tab suelta los controles. La mirada sigue siendo del jugador.

@export_group("Velocidades")
@export var bridge_speed := 6.0
@export var trolley_speed := 6.0
@export var hoist_speed := 3.0
@export var acceleration := 3.0
@export var precision_factor := 0.4

@export_group("Límites")
@export var trolley_x_range := Vector2(-12.0, 12.0)
@export var bridge_z_range := Vector2(-22.0, 22.0)

@export_group("Monitor")
## FOV de la cámara cenital (rueda del mouse): x = más cerca, y = más lejos.
@export var zoom_range := Vector2(30.0, 90.0)

@onready var bridge: Node3D = $Puente
@onready var trolley: Node3D = $Puente/Carro
@onready var hanging: HangingMagnet = $Puente/Carro/HangingMagnet
@onready var cam_mount: Marker3D = $Puente/Carro/VistaCenitalMount
@onready var overhead_viewport: SubViewport = $VistaCenital
@onready var overhead_cam: Camera3D = $VistaCenital/CamaraCenital
@onready var screen_mesh: MeshInstance3D = $Consola/Monitor/Imagen
@onready var console_area: Area3D = $Consola/Area3D
@onready var console_label: Label3D = $Consola/Label3D
@onready var hud: CanvasLayer = $HUD

var active := false

var _player: Player = null
var _player_near := false
var _velocity := Vector3.ZERO  # x = carro, y = imán, z = puente
var _zoom := 60.0


func _ready() -> void:
	console_area.body_entered.connect(_on_console_body_entered)
	console_area.body_exited.connect(_on_console_body_exited)
	console_label.visible = false
	# El monitor muestra el feed de la cámara cenital; unshaded para que se
	# lea como pantalla encendida también de noche.
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = overhead_viewport.get_texture()
	screen_mesh.material_override = mat
	overhead_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton:
		# La rueda emite un par pressed/released por muesca: sin este filtro
		# cada muesca aplicaría el paso de zoom dos veces.
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom = maxf(_zoom - 10.0, zoom_range.x)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom = minf(_zoom + 10.0, zoom_range.y)
		elif event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	# La cámara cenital vive dentro del SubViewport (fuera del árbol 3D de la
	# grúa), así que se le copia la pose del carro a mano: mirando recto hacia
	# abajo, con el norte (−Z) hacia arriba de la pantalla — así W sube el
	# puente en el monitor y A/D mueven el carro a izquierda/derecha.
	overhead_cam.global_transform = Transform3D(
			Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP),
			cam_mount.global_position)
	if active:
		_process_controls(delta)
	elif _player_near and not GameState.is_player_busy() \
			and Input.is_action_just_pressed("interact"):
		_enter()


func _process_controls(delta: float) -> void:
	if Input.is_action_just_pressed("exit_mode"):
		_exit()
		return

	if Input.is_action_just_pressed("magnet_toggle"):
		hanging.toggle_magnet()
	elif Input.is_action_just_pressed("magnet_release"):
		hanging.release()

	var factor := precision_factor if Input.is_action_pressed("precision") else 1.0

	var spin := Input.get_axis("magnet_rotate_right", "magnet_rotate_left")
	if spin != 0.0:
		hanging.rotate_carried(spin * factor, delta)

	var target := Vector3(
			Input.get_axis("move_left", "move_right") * trolley_speed,
			Input.get_axis("crane_down", "crane_up") * hoist_speed,
			Input.get_axis("move_forward", "move_back") * bridge_speed) * factor
	_velocity = _velocity.lerp(target, acceleration * delta)

	trolley.position.x = clampf(
			trolley.position.x + _velocity.x * delta, trolley_x_range.x, trolley_x_range.y)
	hanging.cable_length = clampf(
			hanging.cable_length - _velocity.y * delta,
			hanging.cable_length_range.x, hanging.cable_length_range.y)
	bridge.position.z = clampf(
			bridge.position.z + _velocity.z * delta, bridge_z_range.x, bridge_z_range.y)

	overhead_cam.fov = lerpf(overhead_cam.fov, _zoom, 8.0 * delta)


func _enter() -> void:
	active = true
	add_to_group("vehiculo_activo")  # el menú de pausa permite Esc acá
	console_label.visible = false
	hud.visible = true
	_velocity = Vector3.ZERO
	overhead_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_player.set_control_enabled(false)
	# El cuerpo queda quieto en la consola pero la mirada sigue siendo suya:
	# se reactiva solo el input de cámara del player (mouse), no el andar.
	_player.set_process_unhandled_input(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _exit() -> void:
	active = false
	remove_from_group("vehiculo_activo")
	console_label.visible = _player_near
	hud.visible = false
	# El monitor queda congelado en el último cuadro (pantalla "en espera").
	overhead_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_player.set_control_enabled(true)


func _on_console_body_entered(body: Node3D) -> void:
	if body is Player:
		_player = body
		_player_near = true
		if not active:
			console_label.visible = true


func _on_console_body_exited(body: Node3D) -> void:
	if body is Player:
		_player_near = false
		console_label.visible = false
