extends Node3D
## Imán electromagnético colgante con lógica de péndulo. Componente compartido:
## el nodo raíz es el pivote (lo mueve la grúa que lo instancia) y el imán
## cuelga debajo balanceándose según la aceleración del pivote.
## Energizado (LMB) atrae el auto más cercano bajo el disco y lo captura;
## release() lo suelta heredando la velocidad del balanceo.

signal car_captured(car: RigidBody3D)
signal car_released(car: RigidBody3D)

@export var cable_length := 3.0
@export var cable_length_range := Vector2(0.8, 6.7)

@export_group("Péndulo")
@export var sway_gravity := 9.8
@export var sway_damping := 1.1
@export var max_sway := 0.9

@export_group("Magnetismo")
@export var pull_accel := 16.0
@export var capture_distance := 0.9

## Del centro del imán al origen del auto colgado (techo pegado al disco).
const CAR_HANG_OFFSET := Vector3(0, -1.85, 0)
## Del origen del auto a su techo, donde "muerde" la fuerza magnética.
const ROOF_OFFSET := Vector3(0, 1.4, 0)

var energized := false
var carried: RigidBody3D = null

@onready var cable: CSGCylinder3D = $Cable
@onready var magnet_body: AnimatableBody3D = $MagnetBody
@onready var detector: Area3D = $MagnetBody/Detector

var _sway := Vector2.ZERO       # desplazamiento angular (rad) en ejes X/Z
var _sway_vel := Vector2.ZERO
var _pivot_vel := Vector3.ZERO
var _prev_pivot := Vector3.ZERO
var _prev_bob := Vector3.ZERO
var _bob_vel := Vector3.ZERO
var _rel_basis := Basis()
var _started := false


func toggle_magnet() -> void:
	if energized or carried:
		release()
	else:
		energized = true


func release() -> void:
	energized = false
	if carried == null:
		return
	var car := carried
	carried = null
	car.freeze = false
	car.sleeping = false
	car.linear_velocity = _bob_vel
	car.angular_velocity = Vector3.ZERO
	car_released.emit(car)


func _physics_process(delta: float) -> void:
	var pivot := global_position
	if not _started:
		_started = true
		_prev_pivot = pivot
		_prev_bob = pivot + Vector3(0, -cable_length, 0)

	var pivot_vel := (pivot - _prev_pivot) / delta
	var pivot_accel := (pivot_vel - _pivot_vel) / delta
	_pivot_vel = pivot_vel
	_prev_pivot = pivot

	# Péndulo de ángulos chicos excitado por la aceleración del pivote.
	var cl := maxf(cable_length, 0.3)
	var sway_accel := Vector2(
			-(sway_gravity / cl) * _sway.x - pivot_accel.x / cl - sway_damping * _sway_vel.x,
			-(sway_gravity / cl) * _sway.y - pivot_accel.z / cl - sway_damping * _sway_vel.y)
	_sway_vel += sway_accel * delta
	_sway = (_sway + _sway_vel * delta).limit_length(max_sway)

	var horizontal := Vector2(sin(_sway.x), sin(_sway.y)) * cl
	var drop := sqrt(maxf(cl * cl - horizontal.length_squared(), 0.01))
	var bob := pivot + Vector3(horizontal.x, -drop, horizontal.y)
	_bob_vel = (bob - _prev_bob) / delta
	_prev_bob = bob

	# El imán y el cable se inclinan siguiendo la dirección del cable.
	var bob_basis := _basis_from_up((pivot - bob).normalized())
	magnet_body.global_transform = Transform3D(bob_basis, bob)
	cable.global_transform = Transform3D(bob_basis, (pivot + bob) * 0.5)
	cable.height = pivot.distance_to(bob)

	if carried:
		carried.global_transform = Transform3D(
				bob_basis * _rel_basis, bob + bob_basis * CAR_HANG_OFFSET)
	elif energized:
		_attract()


func _attract() -> void:
	var bottom: Vector3 = magnet_body.global_position - magnet_body.global_basis.y * 0.2
	var best: RigidBody3D = null
	var best_dist := INF
	for candidate in detector.get_overlapping_bodies():
		if candidate is RigidBody3D and candidate.is_in_group("auto") and not candidate.freeze:
			var dist: float = candidate.global_position.distance_to(bottom)
			if dist < best_dist:
				best_dist = dist
				best = candidate
	if best == null:
		return

	best.sleeping = false
	var hang_target: Vector3 = magnet_body.global_position + CAR_HANG_OFFSET
	if best.global_position.distance_to(hang_target) < capture_distance:
		_capture(best)
	else:
		var roof: Vector3 = best.global_position + best.global_basis * ROOF_OFFSET
		var dir: Vector3 = (bottom - roof).normalized()
		best.apply_central_force(dir * pull_accel * best.mass)


func _capture(car: RigidBody3D) -> void:
	carried = car
	car.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	car.freeze = true
	car.sleeping = false
	_rel_basis = magnet_body.global_basis.inverse() * car.global_basis
	# El enganche amortigua el balanceo de golpe: masa nueva colgando.
	_sway_vel *= 0.5
	car_captured.emit(car)


static func _basis_from_up(up: Vector3) -> Basis:
	var y := up
	var x := y.cross(Vector3.BACK)
	if x.length_squared() < 0.0001:
		x = Vector3.RIGHT
	x = x.normalized()
	var z := x.cross(y)
	return Basis(x, y, z)
