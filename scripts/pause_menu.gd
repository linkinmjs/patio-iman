extends CanvasLayer
## Menú de pausa (Esc): congela el árbol entero (juego, reloj y eventos) y
## ofrece continuar, volver al menú principal o salir. Si el player está
## ocupado en un panel o diálogo, Esc conserva su significado ahí y no
## pausa; manejar una grúa (grupo "vehiculo_activo") sí permite pausar.

@onready var resume_button: Button = $Velo/Centro/Caja/Continuar
@onready var menu_button: Button = $Velo/Centro/Caja/MenuPrincipal
@onready var quit_button: Button = $Velo/Centro/Caja/Salir

var _prev_mouse := Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(_resume)
	menu_button.pressed.connect(_to_main_menu)
	quit_button.pressed.connect(func() -> void: get_tree().quit())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if get_tree().paused:
		_resume()
		get_viewport().set_input_as_handled()
	elif _can_pause():
		_pause()
		get_viewport().set_input_as_handled()


## La tienda y los diálogos usan Esc para cerrarse: mientras el player esté
## ocupado por uno de ellos, la pausa les cede la tecla. La excepción es ir
## al mando de una grúa, que también marca ocupado pero no captura Esc.
func _can_pause() -> bool:
	if not GameState.is_player_busy():
		return true
	return get_tree().get_first_node_in_group("vehiculo_activo") != null


func _pause() -> void:
	_prev_mouse = Input.mouse_mode
	get_tree().paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()


func _resume() -> void:
	get_tree().paused = false
	visible = false
	Input.mouse_mode = _prev_mouse


func _to_main_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0  # por si la pausa agarró un zoom dramático a medias
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
