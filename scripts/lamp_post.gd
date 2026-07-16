extends Node3D
## Farol del patio: se enciende solo cuando es de noche (GameState.is_night),
## con el foco emisivo como feedback además de la luz real.

@onready var light: OmniLight3D = $Luz
@onready var bulb: CSGSphere3D = $Foco

var _mat_off: Material
var _mat_on: StandardMaterial3D


func _ready() -> void:
	_mat_off = bulb.material
	_mat_on = StandardMaterial3D.new()
	_mat_on.albedo_color = Color(1.0, 0.9, 0.6)
	_mat_on.emission_enabled = true
	_mat_on.emission = Color(1.0, 0.85, 0.5)
	_mat_on.emission_energy_multiplier = 2.0


func _process(_delta: float) -> void:
	var night: bool = GameState.is_night()
	if light.visible != night:
		light.visible = night
		bulb.material = _mat_on if night else _mat_off
