extends CanvasLayer
## Menú de trucos para desarrollo (F1): plata, modo fantasma y saltos de
## hora. No congela al player, así se puede salir volando con el fantasma.

@onready var money_button: Button = $Fondo/Filas/Plata
@onready var ghost_button: Button = $Fondo/Filas/Fantasma
@onready var hour_button: Button = $Fondo/Filas/Hora
@onready var recoil_button: Button = $Fondo/Filas/Recoil
@onready var close_button: Button = $Fondo/Filas/Cerrar

var _ghost := false


func _ready() -> void:
	visible = false
	money_button.pressed.connect(func() -> void: GameState.add_money(5000))
	hour_button.pressed.connect(func() -> void:
		GameState.hour = wrapf(GameState.hour + 2.0, 0.0, 24.0))
	ghost_button.pressed.connect(_toggle_ghost)
	recoil_button.pressed.connect(_toggle_recoil)
	close_button.pressed.connect(_toggle)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_F1:
		_toggle()


func _toggle() -> void:
	visible = not visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED


func _toggle_ghost() -> void:
	_ghost = not _ghost
	ghost_button.text = "Modo fantasma: %s" % ("ON" if _ghost else "OFF")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_ghost_mode(_ghost)


## Alterna en caliente entre los dos estilos de retroceso del revólver,
## para compararlos jugando.
func _toggle_recoil() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	player.recoil_style = 1 - player.recoil_style
	recoil_button.text = "Recoil: %s" % ("B (vuelve solo)" if player.recoil_style == 1 \
			else "A (queda desviado)")
