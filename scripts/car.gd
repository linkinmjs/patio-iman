extends RigidBody3D
## Auto chatarra. Se lootea una única vez (a pie, manteniendo E): desprende
## 2-3 partes servibles que saltan del techo. La progresión futura (talentos,
## herramientas) va a mejorar cantidad y velocidad de extracción.

const CarPartScene := preload("res://scenes/car_part.tscn")

var looted := false


func loot() -> void:
	if looted:
		return
	looted = true
	_dim_paint()
	for i in randi_range(2, 3) + int(GameState.effect("loot_extra_parts", 0)):
		var part := CarPartScene.instantiate()
		part.type = part.random_type()
		get_parent().add_child(part)
		part.global_position = global_position + global_basis * Vector3(
				randf_range(-0.4, 0.4), 1.9, randf_range(-1.0, 1.0))
		part.apply_central_impulse(Vector3(
				randf_range(-1.5, 1.5), randf_range(1.0, 2.0), randf_range(-1.5, 1.5)) * part.mass)


## Feedback de auto ya looteado: pintura y vidrios quedan apagados.
func _dim_paint() -> void:
	for child in get_children():
		var csg := child as CSGPrimitive3D
		if csg == null or csg.material == null:
			continue
		var faded: StandardMaterial3D = csg.material.duplicate()
		faded.albedo_color = faded.albedo_color.darkened(0.55)
		csg.material = faded
