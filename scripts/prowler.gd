extends Node3D
## El Merodeador: algunas noches aparece en el borde del patio y camina
## lentamente hacia el operario, mirándolo fijo. Sostenerle la linterna
## encima lo disuelve; si llega demasiado cerca, zoom dramático, se
## desvanece y el operario murmura. Nunca ataca (ver prompt-lore: el
## peligro es la sensación, no el game over). Falta su sonido (sistema
## de audio pendiente).

@export var chance := 0.4
@export var min_day := 2  ## las primeras noches no sale
@export var walk_speed := 0.6
@export var appear_hour := 22.5  ## en horas continuas (24.5 = 0:30)
@export var flash_time := 1.5  ## segundos de linterna para disolverlo
@export var scare_distance := 3.5
@export var dialogue: DialogueResource

enum State { HIDDEN, STALKING, LEAVING }

@onready var body: Node3D = $Cuerpo

var _state := State.HIDDEN
var _armed_tonight := false
var _done_tonight := false
var _flash_left := 0.0
var _forced := false  ## debug: aparición forzada ignora restricciones


func _ready() -> void:
	GameState.day_started.connect(func(_day: int) -> void: _reset())
	body.visible = false
	_reset()


func force_appear() -> void:
	# Para debug: aparece sin importar la hora, el día, o si está armado.
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_forced = true
		_appear(player)


func _reset() -> void:
	_done_tonight = false
	_armed_tonight = GameState.day >= min_day and randf() < chance
	_state = State.HIDDEN
	body.visible = false


func _physics_process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	match _state:
		State.HIDDEN:
			if _armed_tonight and not _done_tonight and GameState.is_night() \
					and _continuous_hour() >= appear_hour:
				_appear(player)
		State.STALKING:
			_stalk(player, delta)


func _continuous_hour() -> float:
	var h: float = GameState.hour
	return h + 24.0 if h < 9.0 else h


func _appear(player: Node3D) -> void:
	_state = State.STALKING
	_flash_left = flash_time
	var angle := randf() * TAU
	var pos: Vector3 = player.global_position + Vector3(cos(angle), 0, sin(angle)) * 25.0
	pos.x = clampf(pos.x, -27.0, 27.0)
	pos.z = clampf(pos.z, -27.0, 27.0)
	pos.y = 0.0
	global_position = pos
	body.visible = true


func _stalk(player, delta: float) -> void:
	# Si fue forzado en debug, ignora la restricción de noche.
	if not _forced and not GameState.is_night():
		_vanish()
		return
	var target: Vector3 = player.global_position
	look_at(Vector3(target.x, global_position.y, target.z))
	var flat := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if flat.length() <= scare_distance:
		_scare(player)
		return
	global_position += flat.normalized() * walk_speed * delta
	# La linterna sostenida encima lo deshace (¿o nunca estuvo?).
	if _lit_by_flashlight(player):
		_flash_left -= delta
		if _flash_left <= 0.0:
			_vanish()
	else:
		_flash_left = minf(_flash_left + delta * 0.5, flash_time)


func _lit_by_flashlight(player) -> bool:
	var flashlight = player.get_node_or_null("Head/Linterna")
	if flashlight == null or not flashlight.visible:
		return false
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var to_me: Vector3 = (global_position + Vector3(0, 1.4, 0)) - cam.global_position
	if to_me.length() > 24.0:
		return false
	return (-cam.global_basis.z).angle_to(to_me.normalized()) < deg_to_rad(14.0)


func _scare(player) -> void:
	_state = State.LEAVING
	_done_tonight = true
	await player.focus_on(global_position + Vector3(0, 1.55, 0), 1.2)
	_fade_out()
	if dialogue:
		player.play_dialogue(dialogue)


func _vanish() -> void:
	_state = State.LEAVING
	_done_tonight = true
	_fade_out()


func _fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(body, "scale", Vector3.ONE * 0.05, 0.8) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		body.visible = false
		body.scale = Vector3.ONE
		_state = State.HIDDEN)
