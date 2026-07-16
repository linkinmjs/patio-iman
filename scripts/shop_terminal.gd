extends Node3D
## Terminal de compras del patio: muestra el catálogo de mejoras de GameState
## con una fila por ítem (nombre, nivel, descripción del próximo nivel y botón
## con el precio). Congela el control del player y libera el mouse mientras el
## panel está abierto; E o Esc lo cierran.

@onready var area: Area3D = $Area3D
@onready var label: Label3D = $Label3D
@onready var panel: CanvasLayer = $Panel
@onready var rows: VBoxContainer = $Panel/Fondo/Contenido/Filas

var _player: Node3D = null
var _player_near := false
var _showing := false


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	GameState.money_changed.connect(_on_money_changed)
	label.visible = false
	panel.visible = false


func _physics_process(_delta: float) -> void:
	if _showing:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_cancel"):
			_close()
		return
	if _player_near and Input.is_action_just_pressed("interact"):
		_open()


func _open() -> void:
	_build_rows()
	panel.visible = true
	_showing = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _player:
		_player.set_control_enabled(false)


func _close() -> void:
	panel.visible = false
	_showing = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _player:
		_player.set_control_enabled(true)


func _build_rows() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	for id in GameState.UPGRADE_CATALOG:
		var info: Dictionary = GameState.UPGRADE_CATALOG[id]
		var req: String = info.get("requires", "")
		if req != "" and GameState.upgrade_level(req) == 0:
			continue  # oculto hasta comprar el requisito
		if info.get("repeatable", false):
			# Consumible: por ahora el único es la munición del revólver.
			_add_row("%s  [×%d]" % [info["name"], GameState.ammo],
					str(info["desc"]), int(info["price"]), id)
		else:
			var levels: Array = info["levels"]
			var level := GameState.upgrade_level(id)
			var name_text := "%s  [%d/%d]" % [info["name"], level, levels.size()]
			if level < levels.size():
				_add_row(name_text, str(levels[level]["desc"]),
						int(levels[level]["price"]), id)
			else:
				_add_row(name_text, "Nivel máximo.", -1, id)


## Una fila del panel; price < 0 = sin nada más para comprar (MAX).
func _add_row(name_text: String, desc_text: String, price: int, id: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var name_label := Label.new()
	name_label.text = name_text
	name_label.custom_minimum_size.x = 250
	name_label.add_theme_font_size_override("font_size", 18)
	row.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = desc_text
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_font_size_override("font_size", 15)
	row.add_child(desc_label)

	var buy := Button.new()
	buy.custom_minimum_size.x = 90
	if price >= 0:
		buy.text = "$%d" % price
		buy.disabled = GameState.money < price
		buy.pressed.connect(GameState.purchase.bind(id))
	else:
		buy.text = "MAX"
		buy.disabled = true
	row.add_child(buy)
	rows.add_child(row)


func _on_money_changed(_total: int, _delta: int) -> void:
	# Diferido: la compra llega desde el "pressed" de un botón que la
	# reconstrucción va a liberar.
	if _showing:
		_build_rows.call_deferred()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player = body
		_player_near = true
		label.visible = true


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		label.visible = false
