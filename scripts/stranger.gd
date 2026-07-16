extends Node3D
## NPC misterioso: cuando el player entra en la zona de avistamiento, se
## asoma por encima de la pared y lo mira fijo. Si el player lo divisa
## (lo tiene cerca del centro de la vista, con línea de visión libre),
## dispara el zoom dramático del player, se esconde y deja un monólogo.
## Si nadie lo mira, al rato se esconde solo (nadie le cree al operario).
## Evento único por partida.

@export var dialogue: DialogueResource  ## monólogo del player tras verlo
@export var peek_height := 1.2
@export var peek_time := 0.9
@export var watch_timeout := 12.0  ## segundos asomado antes de rendirse
@export var focus_hold := 1.4
@export var view_angle_deg := 35.0
@export var max_view_distance := 45.0

enum State { HIDDEN, PEEKING, SPOTTED, DONE }

@onready var trigger: Area3D = $Trigger
@onready var body: Node3D = $Cuerpo
@onready var head: Node3D = $Cuerpo/Cabeza

var _state := State.HIDDEN
var _player = null  # sin tipo: usa focus_on/play_dialogue del script del player
var _watch_left := 0.0
var _base_y := 0.0


func _ready() -> void:
	trigger.body_entered.connect(_on_trigger_entered)
	_base_y = body.position.y


func _physics_process(delta: float) -> void:
	if _state != State.PEEKING or _player == null:
		return
	# Mira fijo al player mientras está asomado.
	var target: Vector3 = _player.global_position
	body.look_at(Vector3(target.x, body.global_position.y, target.z))
	_watch_left -= delta
	if _watch_left <= 0.0:
		_hide()
	elif _player_spots_me():
		_spotted()


func _on_trigger_entered(node: Node3D) -> void:
	if _state != State.HIDDEN or not node.is_in_group("player"):
		return
	_player = node
	_state = State.PEEKING
	_watch_left = watch_timeout
	var tw := create_tween()
	tw.tween_property(body, "position:y", _base_y + peek_height, peek_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## "Divisarlo": el player está en control (no en una grúa ni en un panel),
## tiene la cabeza del NPC cerca del centro de la vista y nada la tapa.
func _player_spots_me() -> bool:
	if not _player.is_physics_processing():
		return false
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var to_head: Vector3 = head.global_position - cam.global_position
	if to_head.length() > max_view_distance:
		return false
	if (-cam.global_basis.z).angle_to(to_head.normalized()) > deg_to_rad(view_angle_deg):
		return false
	var query := PhysicsRayQueryParameters3D.create(
			cam.global_position, head.global_position, 1, [_player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _spotted() -> void:
	_state = State.SPOTTED
	await _player.focus_on(head.global_position, focus_hold)
	_hide()
	if dialogue:
		_player.play_dialogue(dialogue)


func _hide() -> void:
	_state = State.DONE
	set_physics_process(false)
	var tw := create_tween()
	tw.tween_property(body, "position:y", _base_y, peek_time * 0.7) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
