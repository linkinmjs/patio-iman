extends CanvasLayer
## Menú de trucos para desarrollo (F1): plata, modo fantasma y saltos de
## hora. No congela al player, así se puede salir volando con el fantasma.

@onready var money_button: Button = $Fondo/Filas/Plata
@onready var ghost_button: Button = $Fondo/Filas/Fantasma
@onready var hour_button: Button = $Fondo/Filas/Hora
@onready var recoil_button: Button = $Fondo/Filas/Recoil
@onready var weather_button: Button = $Fondo/Filas/Clima
@onready var ufo_button: Button = $Fondo/Filas/Ovni
@onready var prowler_button: Button = $Fondo/Filas/Merodeador
@onready var close_button: Button = $Fondo/Filas/Cerrar

var _ghost := false


func _ready() -> void:
	visible = false
	money_button.pressed.connect(func() -> void: GameState.add_money(5000))
	hour_button.pressed.connect(_skip_hours)
	ghost_button.pressed.connect(_toggle_ghost)
	recoil_button.pressed.connect(_toggle_recoil)
	weather_button.pressed.connect(_cycle_weather)
	ufo_button.pressed.connect(_force_ufo)
	prowler_button.pressed.connect(_force_prowler)
	close_button.pressed.connect(_toggle)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_F1:
		_toggle()


func _toggle() -> void:
	visible = not visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED


## Salta la hora respetando el tope de las 03:00: si el salto cae en la
## madrugada muerta, el reloj queda plantado ahí como en el juego normal.
func _skip_hours() -> void:
	GameState.hour = wrapf(GameState.hour + 2.0, 0.0, 24.0)
	if GameState.hour > GameState.clock_stop_hour and GameState.hour < GameState.day_start_hour:
		GameState.hour = GameState.clock_stop_hour
		GameState.clock_stopped = true


func _toggle_ghost() -> void:
	_ghost = not _ghost
	ghost_button.text = "Modo fantasma: %s" % ("ON" if _ghost else "OFF")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_ghost_mode(_ghost)


func _cycle_weather() -> void:
	var keys: Array = GameState.WEATHERS.keys()
	var i: int = keys.find(GameState.weather)
	GameState.weather = keys[(i + 1) % keys.size()]
	weather_button.text = "Clima: %s" % GameState.weather


func _force_ufo() -> void:
	var spawner = get_tree().root.get_child(0).get_node_or_null("OvniSpawner")
	if spawner and spawner.has_method("force_launch"):
		spawner.force_launch()
		ufo_button.text = "OVNI: ¡lanzado!"
		await get_tree().create_timer(1.0).timeout
		ufo_button.text = "Forzar OVNI"


func _force_prowler() -> void:
	var prowler = get_tree().root.get_child(0).get_node_or_null("Merodeador")
	if prowler and prowler.has_method("force_appear"):
		prowler.force_appear()
		prowler_button.text = "Merodeador: ¡apareciendo!"
		await get_tree().create_timer(1.0).timeout
		prowler_button.text = "Forzar Merodeador"


## Alterna en caliente entre los dos estilos de retroceso del revólver,
## para compararlos jugando.
func _toggle_recoil() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	player.recoil_style = 1 - player.recoil_style
	recoil_button.text = "Recoil: %s" % ("B (vuelve solo)" if player.recoil_style == 1 \
			else "A (queda desviado)")
