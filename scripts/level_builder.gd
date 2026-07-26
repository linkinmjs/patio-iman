extends Node3D
## Construye el nivel real del patio a partir de una grilla top-down (el
## maquetador). Genera piso y muros de chatarra con colisión, tiñe las zonas,
## e instancia las ESCENAS REALES de cada elemento en su celda. Los sistemas
## (día/noche, OVNI, merodeador, debug, HUD) viven en la escena que hospeda
## este script; acá solo se arma la geometría y se colocan los elementos.
##
## Grilla: '.' baldío/afuera · 'o' patio · 'h' hogar · 'w' trabajo ·
## 'i' industrial · 'x' chatarra/muro. Norte = arriba (−Z). Patio centrado
## en el origen (los eventos nocturnos asumen eso).

@export var cell_size := 4.0
@export var wall_height := 6.2
## Altura del pórtico (grúa fija). Alto a propósito: la grúa debe pasar el auto
## por encima de las paredes de chatarra. Ajustable desde el inspector.
@export var portico_height := 14.0
const ROWS := 24
const COLS := 24

const GRID := [
	"........................",
	"........................",
	"........................",
	"........................",
	"........xxxxxxxxxx......",
	"........xiiiiiiiix......",
	"..xxxxxxxxxxxxxxixx.....",
	"..xxxxxxxxwwixiiiix.....",
	"..xxooooxxwwiiiiiixxxxx.",
	"..xxxxxoxxwwiiiiiixxoox.",
	"..xxooooxxwwxxxxxxxxoox.",
	"..ooo.oxxxwwwwwwwxxxoox.",
	"..ooooxxxxwwwwwwwxxxxxx.",
	"..xxxoxxxxowxxxwwxxx....",
	"..xxxoxxxoooxxoooohh....",
	"..xxxooooooooooooohh....",
	"..xxxxxxxooxxxoooo......",
	"........xoox.xoooo......",
	".........oo...oooo......",
	"........................",
	"oooooooooooooooooooooooo",
	"oooooooooooooooooooooooo",
	"........................",
	"........................",
]

const ELEMENTS := [
	{"type": "escotilla", "c": 9, "r": 15},
	{"type": "escotilla", "c": 5, "r": 11},
	{"type": "recepcion", "c": 15, "r": 19},
	{"type": "spawn", "c": 17, "r": 15},
	{"type": "tienda", "c": 5, "r": 22},
	{"type": "oficina", "c": 16, "r": 17},
	{"type": "tiro", "c": 9, "r": 5},
	{"type": "prensa", "c": 16, "r": 8},
	{"type": "farol", "c": 14, "r": 12},
	{"type": "farol", "c": 13, "r": 8},
	{"type": "farol", "c": 4, "r": 11},
	{"type": "farol", "c": 10, "r": 18},
	{"type": "farol", "c": 14, "r": 18},
	{"type": "casilla", "c": 18, "r": 14},
	{"type": "gruamovil", "c": 12, "r": 12},
	{"type": "autos", "c": 10, "r": 15},
	{"type": "carga", "c": 12, "r": 19},
	{"type": "portico", "c": 11, "r": 9},
	{"type": "galpon", "c": 5, "r": 8},
	{"type": "lote", "c": 20, "r": 10},
	{"type": "farol", "c": 7, "r": 22},
	{"type": "porton", "c": 2, "r": 11},
]

const SCENES := {
	"recepcion": preload("res://scenes/reception.tscn"),
	"tienda": preload("res://scenes/shop_terminal.tscn"),
	"oficina": preload("res://scenes/office.tscn"),
	"tiro": preload("res://scenes/shooting_range.tscn"),
	"prensa": preload("res://scenes/press.tscn"),
	"casilla": preload("res://scenes/bunkhouse.tscn"),
	"carga": preload("res://scenes/load_zone.tscn"),
	"gruamovil": preload("res://scenes/tractor_crane.tscn"),
	"farol": preload("res://scenes/lamp_post.tscn"),
	"autos": preload("res://scenes/car.tscn"),
}

const C_GROUND := Color(0.13, 0.11, 0.09)
const C_YARD := Color(0.42, 0.42, 0.44)
const C_WALL := Color(0.32, 0.22, 0.16)
const C_TERROR := Color(0.72, 0.28, 0.20)
const C_LATE := Color(0.50, 0.36, 0.58)
const C_STRUCT := Color(0.40, 0.38, 0.35)

var _mats := {}


func _ready() -> void:
	_build_ground()
	_build_cells()
	for e in ELEMENTS:
		if e.type != "spawn":
			_place_element(e.type, e.c, e.r)
	_reposition_player()


func cell_center(c: int, r: int) -> Vector3:
	var x := (float(c) - COLS / 2.0 + 0.5) * cell_size
	var z := (float(r) - ROWS / 2.0 + 0.5) * cell_size
	return Vector3(x, 0.0, z)


func _mat(color: Color, emissive := false) -> StandardMaterial3D:
	var key := color.to_html() + ("_e" if emissive else "")
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.92
	if emissive:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.4
	_mats[key] = m
	return m


## Caja sólida (piso, muros): StaticBody + BoxShape (colisión primitiva barata).
func _solid_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = _mat(color)
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _floor_patch(pos: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(cell_size, 0.1, cell_size)
	m.mesh = bm
	m.position = pos + Vector3(0, 0.06, 0)
	m.material_override = _mat(color)
	add_child(m)


func _label(pos: Vector3, text: String) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.pixel_size = 0.012
	l.outline_size = 14
	l.modulate = Color(1, 1, 1)
	l.outline_modulate = Color(0, 0, 0, 0.85)
	add_child(l)


func _zone_color(ch: String) -> Color:
	match ch:
		"h":
			return C_YARD.lerp(Color(0.85, 0.6, 0.3), 0.20)
		"i":
			return C_YARD.lerp(Color(0.4, 0.55, 0.7), 0.20)
		_:
			return C_YARD


func _build_ground() -> void:
	_solid_box(Vector3(0, -0.25, 0), Vector3(COLS * cell_size, 0.5, ROWS * cell_size), C_GROUND)


func _build_cells() -> void:
	for r in range(ROWS):
		var row: String = GRID[r]
		for c in range(row.length()):
			var ch := row[c]
			var p := cell_center(c, r)
			if ch == "x":
				_solid_box(p + Vector3(0, wall_height / 2.0, 0),
						Vector3(cell_size, wall_height, cell_size), C_WALL)
			elif ch == "o" or ch == "h" or ch == "w" or ch == "i":
				_floor_patch(p, _zone_color(ch))


func _place_element(type: String, c: int, r: int) -> void:
	var p := cell_center(c, r)
	if SCENES.has(type):
		var n: Node3D = SCENES[type].instantiate()
		# Cuerpos con gravedad (autos, grúa) parten apenas elevados para asentar.
		if type == "autos" or type == "gruamovil":
			n.position = p + Vector3(0, 0.4, 0)
		else:
			n.position = p
		add_child(n)
		return
	match type:
		"portico":
			_make_portico(p)
		"galpon":
			_make_galpon(p)
		"lote":
			_solid_box(p + Vector3(0, 1.4, 0), Vector3(2.8, 2.8, 2.8), C_LATE)
			_label(p + Vector3(0, 3.4, 0), "Lote oculto (late)")
		"escotilla":
			_make_marker(p, "Escotilla → túnel")
		"porton":
			_make_marker(p, "Portón → bosque")
		_:
			_make_marker(p, type)


func _make_marker(base: Vector3, text: String) -> void:
	_floor_patch(base + Vector3(0, 0.04, 0), C_TERROR)
	_label(base + Vector3(0, 1.4, 0), text)


func _make_portico(base: Vector3) -> void:
	var h := portico_height
	var span := cell_size * 1.8
	_solid_box(base + Vector3(-span / 2.0, h / 2.0, 0), Vector3(0.5, h, 0.5), C_STRUCT)
	_solid_box(base + Vector3(span / 2.0, h / 2.0, 0), Vector3(0.5, h, 0.5), C_STRUCT)
	_solid_box(base + Vector3(0, h, 0), Vector3(span + 0.5, 0.6, 0.8), C_STRUCT)
	_label(base + Vector3(0, h + 1.0, 0), "Pórtico · estructura día 1 (opera late)")


func _make_galpon(base: Vector3) -> void:
	var h := 4.0
	var half := cell_size * 0.9
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_solid_box(base + Vector3(sx * half, h / 2.0, sz * half), Vector3(0.35, h, 0.35), C_STRUCT)
	# Techo plano sobre los postes.
	var roof := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(half * 2.0 + 0.6, 0.3, half * 2.0 + 0.6)
	roof.mesh = bm
	roof.position = base + Vector3(0, h, 0)
	roof.material_override = _mat(C_STRUCT)
	add_child(roof)
	_label(base + Vector3(0, h + 1.0, 0), "Galpón (mid)")


func _reposition_player() -> void:
	var player := get_node_or_null("Player")
	if player == null:
		return
	var sc := Vector2i(17, 15)
	for e in ELEMENTS:
		if e.type == "spawn":
			sc = Vector2i(e.c, e.r)
	player.position = cell_center(sc.x, sc.y) + Vector3(0, 1.4, 0)
