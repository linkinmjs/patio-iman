extends Node3D
## Estante de la casilla: muestra un cubito dorado por cada trofeo de la
## colección (GameState.trophies) y el nombre del último conseguido.

const SLOT_STEP := 0.4

@onready var caption: Label3D = $Nombre

var _boxes: Array = []
var _gold: StandardMaterial3D


func _ready() -> void:
	_gold = StandardMaterial3D.new()
	_gold.albedo_color = Color(0.9, 0.75, 0.3)
	_gold.metallic = 0.6
	_gold.roughness = 0.35
	GameState.trophy_collected.connect(func(_id: String) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	for box in _boxes:
		box.queue_free()
	_boxes.clear()
	var i := 0
	var last_name := ""
	for id in GameState.trophies:
		var box := CSGBox3D.new()
		box.size = Vector3(0.18, 0.18, 0.18)
		box.position = Vector3(0, 0.13, -0.6 + i * SLOT_STEP)
		box.material = _gold
		add_child(box)
		_boxes.append(box)
		last_name = str(GameState.trophies[id])
		i += 1
	caption.text = last_name
	caption.visible = i > 0
