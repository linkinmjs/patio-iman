extends Node3D
## Maqueta jugable del patio a partir de una grilla top-down (el maquetador).
## Genera piso, muros, zonas de color y placeholders etiquetados de cada
## elemento, e instancia el player para poder caminarlo y "sentir" la
## distribución antes de construir el nivel de verdad.
##
## Grilla: '.' baldío/afuera · 'o' patio · 'h' hogar · 'w' trabajo ·
## 'i' industrial · 'x' chatarra/muro. Norte = arriba (−Z).

## Metros por celda: subilo o bajalo en el inspector para ampliar/achicar TODO
## el nivel de forma proporcional, sin cambiar el diseño de la grilla.
@export var cell_size := 4.0
## Altura de los muros de chatarra (metros).
@export var wall_height := 6.2
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

const C_OUT := Color(0.10, 0.11, 0.13)
const C_NEU := Color(0.60, 0.58, 0.53)
const C_HOME := Color(0.78, 0.54, 0.22)
const C_WORK := Color(0.54, 0.54, 0.57)
const C_IND := Color(0.34, 0.52, 0.63)
const C_WALL := Color(0.34, 0.22, 0.16)
const C_TERROR := Color(0.74, 0.26, 0.18)
const C_LAMP := Color(0.96, 0.76, 0.36)
const C_LATE := Color(0.56, 0.38, 0.66)

var _mats := {}


func _ready() -> void:
	_build_ground()
	_build_cells()
	for e in ELEMENTS:
		if e.type != "spawn":
			_place_element(e.type, e.c, e.r)
	_spawn_player()


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
	m.roughness = 0.9
	if emissive:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.5
	_mats[key] = m
	return m


func _csg_box(pos: Vector3, size: Vector3, color: Color, collision := false) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.material = _mat(color)
	b.use_collision = collision
	add_child(b)
	return b


func _floor_patch(pos: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(cell_size, 0.12, cell_size)
	m.mesh = bm
	m.position = pos + Vector3(0.0, 0.07, 0.0)
	m.material_override = _mat(color)
	add_child(m)


func _label(pos: Vector3, text: String) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.pixel_size = 0.011
	l.outline_size = 14
	l.modulate = Color(1, 1, 1)
	l.outline_modulate = Color(0, 0, 0, 0.85)
	add_child(l)


func _build_ground() -> void:
	var floor := _csg_box(Vector3(0, -0.25, 0), Vector3(COLS * cell_size, 0.5, ROWS * cell_size), C_OUT, true)
	floor.name = "PisoBase"


func _build_cells() -> void:
	for r in range(ROWS):
		var row: String = GRID[r]
		for c in range(row.length()):
			var ch := row[c]
			var p := cell_center(c, r)
			match ch:
				"x":
					_csg_box(p + Vector3(0, wall_height / 2.0, 0), Vector3(cell_size, wall_height, cell_size), C_WALL, true)
				"o":
					_floor_patch(p, C_NEU)
				"h":
					_floor_patch(p, C_HOME)
				"w":
					_floor_patch(p, C_WORK)
				"i":
					_floor_patch(p, C_IND)


func _place_element(type: String, c: int, r: int) -> void:
	var b := cell_center(c, r)
	match type:
		"farol":
			_make_lamp(b)
		"escotilla":
			_make_marker(b, "Escotilla → túnel")
		"porton":
			_make_marker(b, "Portón → bosque")
		"portico":
			_make_portico(b)
		"prensa":
			_make_block(b, Vector3(3.0, 3.6, 3.0), C_IND, "PRENSA")
		"autos":
			_make_block(b, Vector3(1.9, 1.4, 4.0), C_WORK, "Autos")
		"gruamovil":
			_make_block(b, Vector3(2.2, 2.6, 3.4), C_WORK, "Grúa móvil")
		"casilla":
			_make_block(b, Vector3(2.2, 2.4, 2.2), C_HOME, "Casilla")
		"tienda":
			_make_block(b, Vector3(2.2, 3.0, 2.2), C_HOME, "TIENDA (cruzando la calle)")
		"oficina":
			_make_block(b, Vector3(2.4, 3.0, 2.4), C_HOME, "Oficina")
		"galpon":
			_make_block(b, Vector3(4.0, 3.5, 4.0), C_WORK, "Galpón (mid)")
		"lote":
			_make_block(b, Vector3(2.6, 2.8, 2.6), C_LATE, "Lote oculto (late)")
		"tiro":
			_make_block(b, Vector3(1.6, 2.0, 1.6), C_HOME, "Tiro al blanco")
		"recepcion":
			_make_pad(b, C_NEU, "Recepción · entra el camión")
		"carga":
			_make_pad(b, C_IND, "Despacho · se lleva la carga")
		_:
			_make_marker(b, type)


func _make_block(base: Vector3, size: Vector3, color: Color, text: String) -> void:
	_csg_box(base + Vector3(0, size.y / 2.0, 0), size, color, true)
	_label(base + Vector3(0, size.y + 0.7, 0), text)


func _make_pad(base: Vector3, color: Color, text: String) -> void:
	_csg_box(base + Vector3(0, 0.16, 0), Vector3(cell_size * 0.92, 0.3, cell_size * 0.92), color, false)
	_label(base + Vector3(0, 1.1, 0), text)


func _make_marker(base: Vector3, text: String) -> void:
	_csg_box(base + Vector3(0, 0.09, 0), Vector3(cell_size * 0.7, 0.18, cell_size * 0.7), C_TERROR, false)
	_label(base + Vector3(0, 1.2, 0), text)


func _make_lamp(base: Vector3) -> void:
	_csg_box(base + Vector3(0, 2.0, 0), Vector3(0.2, 4.0, 0.2), Color(0.18, 0.18, 0.2), false)
	_csg_box(base + Vector3(0, 4.0, 0), Vector3(0.5, 0.4, 0.5), C_LAMP, true).material = _mat(C_LAMP, true)
	var light := OmniLight3D.new()
	light.position = base + Vector3(0, 3.9, 0)
	light.light_color = C_LAMP
	light.light_energy = 1.6
	light.omni_range = 9.0
	add_child(light)


func _make_portico(base: Vector3) -> void:
	var h := 7.0
	var span := cell_size * 1.7
	_csg_box(base + Vector3(-span / 2.0, h / 2.0, 0), Vector3(0.4, h, 0.4), C_WORK, true)
	_csg_box(base + Vector3(span / 2.0, h / 2.0, 0), Vector3(0.4, h, 0.4), C_WORK, true)
	_csg_box(base + Vector3(0, h, 0), Vector3(span + 0.4, 0.5, 0.6), C_WORK, false)
	_label(base + Vector3(0, h + 0.9, 0), "Pórtico · estructura día 1 (opera late)")


func _spawn_player() -> void:
	var sc := Vector2i(17, 15)
	for e in ELEMENTS:
		if e.type == "spawn":
			sc = Vector2i(e.c, e.r)
	var p: Node3D = preload("res://scenes/player.tscn").instantiate()
	p.position = cell_center(sc.x, sc.y) + Vector3(0, 1.3, 0)
	add_child(p)
