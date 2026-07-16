extends Node3D
## Prensa compactadora. Se opera desde la consola (E), fuera de la tolva.
## Solo compacta si el auto adentro está detenido, centrado y erguido; si no,
## el prompt avisa que hay que acomodarlo mejor. Al terminar, el auto se
## reemplaza por un bloque de chatarra (scrap_block) que el imán puede llevar
## a la zona de carga.

signal car_compacted(block: RigidBody3D)

const ScrapBlockScene := preload("res://scenes/scrap_block.tscn")

@export_group("Criterio de acomodo")
@export var max_offset := 1.0
@export var max_tilt_deg := 12.0
@export var max_speed := 0.35

@export_group("Bono de maniobra")
## Ventana de "drop perfecto" del documento: centro < 0.6 m, ángulo < 7°.
@export var perfect_offset := 0.6
@export var perfect_tilt_deg := 7.0
@export var perfect_bonus := 40

@export_group("Compactación")
@export var compaction_time := 15.0
@export var plate_top_y := 3.4
## La placa termina apoyada sobre el bloque final (0.9 de alto + media placa).
@export var plate_bottom_y := 1.1
## Escala que deja al auto (1.8 × ~1.65 × 4.4) del tamaño del bloque.
@export var squash_scale := Vector3(0.9, 0.5, 0.55)

@onready var slot_detector: Area3D = $Tolva/SlotDetector
@onready var plate: CSGBox3D = $Placa
@onready var console_area: Area3D = $Consola/Area3D
@onready var console_label: Label3D = $Consola/Label3D

var _player_near := false
var _busy := false
var _occupant: RigidBody3D = null
var _scrap_inside := 0


func _ready() -> void:
	slot_detector.body_entered.connect(_on_slot_body_entered)
	slot_detector.body_exited.connect(_on_slot_body_exited)
	console_area.body_entered.connect(_on_console_body_entered)
	console_area.body_exited.connect(_on_console_body_exited)
	console_label.visible = false


func _physics_process(_delta: float) -> void:
	if not _player_near or _busy:
		return
	console_label.text = _prompt_text()
	if Input.is_action_just_pressed("interact"):
		_try_compact()


func _prompt_text() -> String:
	if _occupant == null:
		return "Retirá el bloque" if _scrap_inside > 0 else "Prensa vacía"
	if _is_well_placed(_occupant):
		return "E: Compactar"
	return "Acomodalo mejor"


func _is_well_placed(car: RigidBody3D) -> bool:
	if car.freeze:
		return false  # lo está sosteniendo el imán
	var offset: Vector3 = car.global_position - slot_detector.global_position
	if Vector2(offset.x, offset.z).length() > max_offset:
		return false
	if car.linear_velocity.length() > max_speed:
		return false
	return rad_to_deg(car.global_basis.y.angle_to(Vector3.UP)) <= max_tilt_deg


func _try_compact() -> void:
	if _occupant == null or not _is_well_placed(_occupant):
		return
	_busy = true
	var car := _occupant
	# El acomodo se mide antes de congelar: mejor que la tolerancia mínima
	# (ventana de drop perfecto) paga bono de maniobra.
	var offset: Vector3 = car.global_position - slot_detector.global_position
	var tilt := rad_to_deg(car.global_basis.y.angle_to(Vector3.UP))
	var bonus := perfect_bonus if Vector2(offset.x, offset.z).length() < perfect_offset \
			and tilt < perfect_tilt_deg else 0
	console_label.text = "Compactando..."
	car.freeze = true
	car.sleeping = true

	# Los pistones de alto tonelaje (tienda) acortan el ciclo.
	var cycle := compaction_time * GameState.effect("press_cycle_mult", 1.0)
	var down := create_tween()
	down.set_parallel(true)
	down.tween_property(plate, "position:y", plate_bottom_y, cycle * 0.7) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	down.tween_property(car, "scale", squash_scale, cycle * 0.7) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await down.finished

	# El auto aplastado se reemplaza por un bloque rígido con forma de
	# ladrillo, conservando posición y rumbo.
	var block: RigidBody3D = ScrapBlockScene.instantiate()
	add_sibling(block)
	var fwd := -car.global_basis.z
	block.global_transform = Transform3D(
			Basis(Vector3.UP, atan2(-fwd.x, -fwd.z)), car.global_position)
	block.set_meta("scrap_value", roundi(float(block.get_meta("scrap_value", 120))
			* GameState.effect("press_value_mult", 1.0)))
	if _occupant == car:
		_occupant = null
	car.queue_free()

	var up := create_tween()
	up.tween_property(plate, "position:y", plate_top_y, cycle * 0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await up.finished

	car_compacted.emit(block)
	if bonus > 0:
		GameState.register_income("bonos", bonus)
		console_label.text = "¡Maniobra perfecta! +$%d" % bonus
		await get_tree().create_timer(1.5).timeout
	_busy = false


func _on_slot_body_entered(body: Node3D) -> void:
	if body.is_in_group("auto"):
		_occupant = body
	elif body.is_in_group("chatarra"):
		_scrap_inside += 1


func _on_slot_body_exited(body: Node3D) -> void:
	if body == _occupant:
		_occupant = null
	elif body.is_in_group("chatarra"):
		_scrap_inside = maxi(_scrap_inside - 1, 0)


func _on_console_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		console_label.visible = true


func _on_console_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		console_label.visible = false
