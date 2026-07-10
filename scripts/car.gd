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
	for i in randi_range(2, 3):
		var part := CarPartScene.instantiate()
		part.type = part.random_type()
		get_parent().add_child(part)
		part.global_position = global_position + global_basis * Vector3(
				randf_range(-0.4, 0.4), 1.9, randf_range(-1.0, 1.0))
		part.apply_central_impulse(Vector3(
				randf_range(-1.5, 1.5), randf_range(1.0, 2.0), randf_range(-1.5, 1.5)) * part.mass)
