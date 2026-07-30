extends Control
## Menú principal: pantalla de entrada del juego. "Comenzar jornada"
## reinicia el estado de partida (GameState.reset_run) y carga el patio.

@onready var play_button: Button = $Centro/Caja/Jugar
@onready var quit_button: Button = $Centro/Caja/Salir


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	play_button.pressed.connect(_start)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	play_button.grab_focus()


func _start() -> void:
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/patio.tscn")
