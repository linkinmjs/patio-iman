extends Node3D
## Programa el cruce nocturno del disco volador: algunas noches, en una
## hora sorteada entre las 21:00 y la 1:30, el disco cruza el patio una
## vez. La primera vez que se queda quieto sobre el patio dispara el zoom
## dramático del player (si está a pie).

const UfoScene := preload("res://scenes/ufo.tscn")

@export var chance := 0.35
@export var fly_height := 15.0
@export var area_radius := 26.0

var _tonight_hour := -1.0  # en horas continuas (21.0-25.5); -1 = esta noche no
var _done_today := false
var _revealed := false


func _ready() -> void:
	GameState.day_started.connect(func(_day: int) -> void: _schedule())
	_schedule()


func _schedule() -> void:
	_done_today = false
	_tonight_hour = randf_range(21.0, 25.5) if randf() < chance else -1.0


func _physics_process(_delta: float) -> void:
	if _done_today or _tonight_hour < 0.0:
		return
	var h: float = GameState.hour
	if h < 9.0:
		h += 24.0  # madrugada en horas continuas (0:30 -> 24.5)
	if h >= _tonight_hour:
		_done_today = true
		_launch()


func force_launch() -> void:
	# Para debug: lanzar sin restricciones. No marca _done_today para permitir
	# múltiples lanzamientos en la misma noche al testear.
	_launch()


func _launch() -> void:
	var angle := randf() * TAU
	var edge := Vector3(cos(angle), 0.0, sin(angle)) * area_radius
	var lift := Vector3(0, fly_height, 0)
	var ufo := UfoScene.instantiate()
	add_child(ufo)
	ufo.start_flight(edge + lift, -edge + lift)
	if not _revealed:
		ufo.started_hovering.connect(_reveal.bind(ufo))


func _reveal(ufo: Node3D) -> void:
	if _revealed:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not player.is_physics_processing():
		return  # está en una grúa o un panel: quedará para otra noche
	_revealed = true
	player.focus_on(ufo.global_position, 1.8)
