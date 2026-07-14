extends Node3D
## Zona que compra cuerpos de un grupo dado (chatarra en la zona de carga,
## partes en el pozo). Cuando un cuerpo del grupo queda apoyado y quieto
## adentro, paga su meta "scrap_value", muestra el monto y lo absorbe.

@export var accepted_group := "chatarra"
@export var income_category := "chatarra"  ## rubro del resumen de jornada
@export var settle_speed := 0.5  ## m/s máx. para considerarlo depositado

@onready var area: Area3D = $Area3D
@onready var label: Label3D = $Label3D

var _base_text := ""
var _selling := {}


func _ready() -> void:
	_base_text = label.text


func _physics_process(_delta: float) -> void:
	for body in area.get_overlapping_bodies():
		if body is RigidBody3D and body.is_in_group(accepted_group) \
				and not body.freeze and not _selling.has(body) \
				and body.linear_velocity.length() < settle_speed:
			_sell(body)


func _sell(body: RigidBody3D) -> void:
	_selling[body] = true
	var value := int(body.get_meta("scrap_value", 0))
	GameState.register_income(income_category, value)
	label.text = "+$%d" % value
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		label.text = _base_text)

	# Absorción: se hunde y encoge en vez de desaparecer de golpe.
	body.freeze = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(body, "scale", Vector3.ONE * 0.05, 0.6) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(body, "position:y", body.position.y - 0.5, 0.6)
	tween.chain().tween_callback(func() -> void:
		_selling.erase(body)
		body.queue_free())
