extends Node3D
## Oficina del patio: consola (E) con el balance parcial de la jornada,
## desglosado por la fórmula visible. La jornada ya no se termina acá:
## se termina durmiendo en la casilla.

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
		return
	if _player_near and Input.is_action_just_pressed("interact"):
		_show_balance()


func _show_balance() -> void:
	var inc: Dictionary = GameState.day_income
	var total := int(inc.chatarra) + int(inc.piezas) + int(inc.bonos)
	summary_text.text = (
			"Balance parcial — Jornada %d\n\n" % GameState.day
			+ "Chatarra: $%d\n" % inc.chatarra
			+ "Piezas: $%d\n" % inc.piezas
			+ "Bonos de maniobra: $%d\n\n" % inc.bonos
			+ "Total del día: $%d\n\n" % total
			+ "[E] Cerrar")
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
