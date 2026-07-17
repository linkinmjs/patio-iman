extends Node3D
## Recepción de autos: mientras la jornada está activa entran autos hasta el
## cupo del día, siempre que el pad esté libre y no se pase el presupuesto de
## performance (autos simultáneos en el patio). Placeholder del futuro camión
## de reparto.

const CarScene := preload("res://scenes/car.tscn")

@export var cars_per_day := 8
@export var max_alive_cars := 6  ## presupuesto de performance del documento
@export var spawn_interval := 6.0

@onready var clear_area: Area3D = $Area3D
@onready var label: Label3D = $Label3D

var _delivered_today := 0
var _cooldown := 2.0


func _ready() -> void:
	GameState.day_started.connect(func(_day: int) -> void:
		_delivered_today = 0)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not GameState.can_earn():
		label.text = "Recepción — cerrada"
		return
	var quota := cars_per_day + int(GameState.effect("extra_cars_per_day", 0))
	label.text = "Recepción — %d/%d hoy" % [_delivered_today, quota]
	if _delivered_today >= quota or _cooldown > 0.0:
		return
	if get_tree().get_nodes_in_group("auto").size() >= max_alive_cars:
		return
	if not clear_area.get_overlapping_bodies().is_empty():
		return
	_spawn_car()
	_cooldown = spawn_interval


func _spawn_car() -> void:
	var car := CarScene.instantiate()
	add_sibling(car)
	car.global_transform = Transform3D(
			Basis(Vector3.UP, randf_range(0.0, TAU)),
			global_position + Vector3(randf_range(-0.4, 0.4), 0.6, randf_range(-0.4, 0.4)))
	_delivered_today += 1
