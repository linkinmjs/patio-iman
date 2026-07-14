extends Node3D
## Oficina del patio: consola (E) para cerrar la jornada. Muestra el resumen
## de ingresos del día desglosado por la fórmula visible y arranca la
## jornada siguiente al confirmar.

@onready var area: Area3D = $Area3D
@onready var label: Label3D = $Label3D
@onready var panel: CanvasLayer = $Resumen
@onready var summary_text: Label = $Resumen/Fondo/Texto

var _player_near := false
var _showing := false


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	label.visible = false
	panel.visible = false


func _physics_process(_delta: float) -> void:
	if _showing:
		if Input.is_action_just_pressed("interact"):
			panel.visible = false
			_showing = false
			GameState.start_next_day()
		return
	if _player_near and Input.is_action_just_pressed("interact"):
		_end_day()


func _end_day() -> void:
	var s := GameState.end_day()
	summary_text.text = (
			"Jornada %d terminada\n\n" % s.day
			+ "Chatarra: $%d\n" % s.chatarra
			+ "Piezas: $%d\n" % s.piezas
			+ "Bonos de maniobra: $%d\n\n" % s.bonos
			+ "Total del día: $%d\n\n" % s.total
			+ "[E] Comenzar jornada %d" % (s.day + 1))
	panel.visible = true
	_showing = true


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		label.visible = true


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		label.visible = false
