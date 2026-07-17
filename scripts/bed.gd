extends Node3D
## Catre de la casilla: la única forma de terminar la jornada. Desde la
## hora de sueño (GameState.can_sleep) E funde a negro, muestra el resumen
## del día y otro E despierta a las 9:00 del día siguiente.

@onready var area: Area3D = $Area3D
@onready var label: Label3D = $Label3D
@onready var screen: CanvasLayer = $Pantalla
@onready var fade: ColorRect = $Pantalla/Fade
@onready var summary_text: Label = $Pantalla/Fade/Texto

enum Stage { AWAKE, FALLING_ASLEEP, SUMMARY }

var _player_near := false
var _stage := Stage.AWAKE


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	label.visible = false
	screen.visible = false
	fade.color.a = 0.0


func _physics_process(_delta: float) -> void:
	match _stage:
		Stage.AWAKE:
			if not _player_near:
				return
			if GameState.can_sleep():
				label.text = "Dormir [E]"
				if Input.is_action_just_pressed("interact"):
					_sleep()
			else:
				label.text = "Todavía es temprano para dormir"
		Stage.SUMMARY:
			if Input.is_action_just_pressed("interact"):
				_wake_up()


func _sleep() -> void:
	_stage = Stage.FALLING_ASLEEP
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_control_enabled(false)
	var s: Dictionary = GameState.end_day()
	screen.visible = true
	summary_text.text = ""
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 1.4)
	await tw.finished
	summary_text.text = (
			"Jornada %d terminada\n\n" % s.day
			+ "Chatarra: $%d\n" % s.chatarra
			+ "Piezas: $%d\n" % s.piezas
			+ "Bonos de maniobra: $%d\n\n" % s.bonos
			+ "Total del día: $%d\n\n" % s.total
			+ "[E] Despertar — 9:00")
	_stage = Stage.SUMMARY


func _wake_up() -> void:
	_stage = Stage.FALLING_ASLEEP  # bloquea E hasta terminar el fundido
	summary_text.text = ""
	GameState.start_next_day()
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 1.0)
	await tw.finished
	screen.visible = false
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_control_enabled(true)
	_stage = Stage.AWAKE


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		label.visible = true


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		label.visible = false
