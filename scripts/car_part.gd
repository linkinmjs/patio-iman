extends RigidBody3D
## Parte servible desprendida de un auto al lootearlo. El player la lleva a
## mano hasta el pozo, que paga según su tipo. El valor queda en la meta
## "scrap_value" para que la zona de venta no conozca los tipos.

enum Type { LLANTA, BATERIA, ALTERNADOR, CATALIZADOR }

const DATA := {
	Type.LLANTA: {"nombre": "Llanta", "valor": 25, "color": Color(0.25, 0.25, 0.28)},
	Type.BATERIA: {"nombre": "Batería", "valor": 40, "color": Color(0.2, 0.65, 0.3)},
	Type.ALTERNADOR: {"nombre": "Alternador", "valor": 70, "color": Color(0.85, 0.55, 0.15)},
	Type.CATALIZADOR: {"nombre": "Catalizador", "valor": 150, "color": Color(0.7, 0.3, 0.85)},
}

## Los comunes se repiten para pesar la tirada; el catalizador es el premio.
const LOOT_TABLE: Array[Type] = [
	Type.LLANTA, Type.LLANTA, Type.BATERIA, Type.BATERIA,
	Type.ALTERNADOR, Type.ALTERNADOR, Type.CATALIZADOR,
]

@export var type := Type.LLANTA


static func random_type() -> Type:
	return LOOT_TABLE[randi() % LOOT_TABLE.size()]


func _ready() -> void:
	var data: Dictionary = DATA[type]
	set_meta("scrap_value", data.valor)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = data.color
	mat.roughness = 0.7
	$Visual.material = mat
	$Etiqueta.text = "%s · $%d" % [data.nombre, data.valor]
