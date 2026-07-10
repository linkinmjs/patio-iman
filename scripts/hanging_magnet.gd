extends Node3D
## Imán electromagnético colgante con lógica de péndulo. Componente compartido:
## el nodo raíz es el pivote (lo mueve la grúa que lo instancia) y el imán
## cuelga debajo balanceándose según la aceleración del pivote.
## Energizado (LMB) atrae el auto o bloque de chatarra más cercano bajo el
## disco y lo captura; release() lo suelta heredando la velocidad del balanceo.
## El imán tiene rumbo (yaw) propio: sigue hacia donde apunta la grúa que lo
## cuelga y admite rotación manual (rotate_carried); el auto capturado cuelga
## nivelado y gira junto con ese rumbo.
## Feedback de energía: con el imán prendido (o con carga) el disco se pone
## naranja emisivo y proyecta luz hacia abajo; el estado persiste aunque el
## operador se baje de la grúa.

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
@export var rotate_speed := 1.2  # rad/s de rotación manual del auto colgado

## Luz vertical entre el centro del imán y la cara de agarre del cuerpo
## (media altura del disco + aire).
const HANG_CLEARANCE := 0.45

var energized := false
var carried: RigidBody3D = null

@onready var cable: CSGCylinder3D = $Cable
@onready var magnet_body: AnimatableBody3D = $MagnetBody
@onready var detector: Area3D = $MagnetBody/Detector
@onready var magnet_visual: CSGCylinder3D = $MagnetBody/ImanVisual
@onready var status_light: OmniLight3D = $MagnetBody/StatusLight

var _mat_off: Material
var _mat_on: StandardMaterial3D

var _sway := Vector2.ZERO       # desplazamiento angular (rad) en ejes X/Z
var _sway_vel := Vector2.ZERO
var _pivot_vel := Vector3.ZERO
var _prev_pivot := Vector3.ZERO
var _prev_bob := Vector3.ZERO
var _bob_vel := Vector3.ZERO
var _yaw_manual := 0.0          # rotación manual acumulada sobre el rumbo base
var _rel_yaw := 0.0             # yaw del auto relativo al imán al capturarlo
var _started := false


func _ready() -> void:
	_mat_off = magnet_visual.material
	_mat_on = StandardMaterial3D.new()
	_mat_on.albedo_color = Color(1.0, 0.45, 0.15)
	_mat_on.emission_enabled = true
	_mat_on.emission = Color(1.0, 0.4, 0.1)
	_mat_on.emission_energy_multiplier = 1.4


func toggle_magnet() -> void:
	if energized or carried:
		release()
	else:
		energized = true
		_update_power_visuals()


func release() -> void:
	energized = false
	_update_power_visuals()
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

	# El imán se inclina siguiendo el cable y gira con el rumbo de la grúa
	# más la rotación manual.
	var bob_basis := _tilted_basis((pivot - bob).normalized(), _magnet_yaw())
	magnet_body.global_transform = Transform3D(bob_basis, bob)
	cable.global_transform = Transform3D(bob_basis, (pivot + bob) * 0.5)
	cable.height = pivot.distance_to(bob)

	if carried:
		var hang := Vector3(0, -(HANG_CLEARANCE + _grab_top(carried)), 0)
		carried.global_transform = Transform3D(
				bob_basis * Basis(Vector3.UP, _rel_yaw), bob + bob_basis * hang)
	elif energized:
		_attract()


func _attract() -> void:
	var bottom: Vector3 = magnet_body.global_position - magnet_body.global_basis.y * 0.2
	var best: RigidBody3D = null
	var best_dist := INF
	for candidate in detector.get_overlapping_bodies():
		if candidate is RigidBody3D and not candidate.freeze \
				and (candidate.is_in_group("auto") or candidate.is_in_group("chatarra")):
			var dist: float = candidate.global_position.distance_to(bottom)
			if dist < best_dist:
				best_dist = dist
				best = candidate
	if best == null:
		return

	best.sleeping = false
	# Mismo cálculo que la posición de enganche real (rotada por la inclinación
	# del péndulo); si no coinciden, el auto puede "aprobar" el chequeo estando
	# lejos del punto donde en verdad va a aparecer al capturarlo.
	var hang_target: Vector3 = magnet_body.global_position \
			+ magnet_body.global_basis * Vector3(0, -(HANG_CLEARANCE + _grab_top(best)), 0)
	if best.global_position.distance_to(hang_target) < capture_distance:
		_capture(best)
	else:
		var top: Vector3 = best.global_position + best.global_basis * Vector3(0, _grab_top(best), 0)
		var dir: Vector3 = (bottom - top).normalized()
		best.apply_central_force(dir * pull_accel * best.mass)


func _capture(car: RigidBody3D) -> void:
	carried = car
	car.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	car.freeze = true
	car.sleeping = false
	# Solo se conserva el rumbo del auto: cuelga nivelado con el techo pegado
	# al disco, sin heredar la inclinación con la que estaba apoyado.
	_rel_yaw = _yaw_of(car.global_basis) - _magnet_yaw()
	# El enganche amortigua el balanceo de golpe: masa nueva colgando.
	_sway_vel *= 0.5
	car_captured.emit(car)


## Gira el auto colgado alrededor del cable. axis > 0 = antihorario.
func rotate_carried(axis: float, delta: float) -> void:
	_yaw_manual += axis * rotate_speed * delta


func _update_power_visuals() -> void:
	var on := energized or carried != null
	magnet_visual.material = _mat_on if on else _mat_off
	status_light.visible = on


## Altura de la cara de agarre sobre el origen del cuerpo. Cada escena
## imantable la declara en su meta "grab_top_y" (auto 1.4, bloque 0.9).
static func _grab_top(body: RigidBody3D) -> float:
	return float(body.get_meta("grab_top_y", 1.4))


func _magnet_yaw() -> float:
	# El eje X del pivote queda horizontal aunque el brazo tenga inclinación
	# (la cadena torreta/brazo solo combina yaw y pitch), así que da el rumbo
	# de la grúa sin ensuciarse con el pitch.
	var right := global_basis.x
	return atan2(-right.z, right.x) + _yaw_manual


static func _yaw_of(basis: Basis) -> float:
	var fwd := -basis.z
	if Vector2(fwd.x, fwd.z).length_squared() < 0.001:
		fwd = -basis.y  # auto parado de punta: el frente no define rumbo
	return atan2(-fwd.x, -fwd.z)


## Basis con Y alineado a `up` (inclinación mínima desde la vertical) y
## girada `yaw` alrededor del cable.
static func _tilted_basis(up: Vector3, yaw: float) -> Basis:
	var spin := Basis(Vector3.UP, yaw)
	var axis := Vector3.UP.cross(up)
	if axis.length_squared() < 0.000001:
		return spin
	return Basis(axis.normalized(), Vector3.UP.angle_to(up)) * spin
