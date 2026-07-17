extends AnimatableBody3D
## Disco volador: cruza el patio de noche, se detiene un momento sobre el
## medio y sigue de largo. Si le acertás un tiro (único "uso real" del
## revólver) suelta un trofeo y escapa disparado. No responde a nada más.

signal started_hovering

const TrophyScene := preload("res://scenes/trophy.tscn")

@export var cruise_speed := 4.0
@export var hover_time := 4.5

enum Phase { INBOUND, HOVER, OUTBOUND, ESCAPE }

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _mid := Vector3.ZERO
var _phase := Phase.INBOUND
var _hover_left := 0.0
var _escape_dir := Vector3.UP
var _time := 0.0
var _shot := false


func start_flight(from: Vector3, to: Vector3) -> void:
	_from = from
	_to = to
	_mid = (from + to) * 0.5
	global_position = from
	_hover_left = hover_time


func _physics_process(delta: float) -> void:
	_time += delta
	rotate_y(delta * 1.5)  # el disco gira sobre sí mismo
	match _phase:
		Phase.INBOUND:
			_advance_towards(_mid, delta)
			if global_position.distance_to(_mid) < 0.5:
				_phase = Phase.HOVER
				started_hovering.emit()
		Phase.HOVER:
			global_position.y += sin(_time * 2.2) * 0.012  # bamboleo
			_hover_left -= delta
			if _hover_left <= 0.0:
				_phase = Phase.OUTBOUND
		Phase.OUTBOUND:
			_advance_towards(_to, delta)
			if global_position.distance_to(_to) < 1.0:
				queue_free()
		Phase.ESCAPE:
			global_position += _escape_dir * 45.0 * delta


func _advance_towards(target: Vector3, delta: float) -> void:
	var offset := target - global_position
	global_position += offset.normalized() * minf(cruise_speed * delta, offset.length())


## Un tiro del revólver lo alcanzó: suelta el trofeo y se va disparado.
func on_shot() -> void:
	if _shot:
		return
	_shot = true
	var trophy: RigidBody3D = TrophyScene.instantiate()
	get_parent().add_child(trophy)
	trophy.global_position = global_position - Vector3(0, 1.2, 0)
	trophy.linear_velocity = Vector3(randf_range(-1.0, 1.0), -2.0, randf_range(-1.0, 1.0))
	_phase = Phase.ESCAPE
	_escape_dir = ((_to - _from).normalized() + Vector3.UP * 1.6).normalized()
	get_tree().create_timer(2.0).timeout.connect(queue_free)
