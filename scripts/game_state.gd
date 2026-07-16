extends Node
## Estado global de la partida (autoload GameState): dinero, jornada y el
## desglose de ingresos del día según la fórmula visible del documento
## (chatarra + piezas + bonos − penalizaciones).
## También lleva las mejoras compradas en la tienda: el catálogo declara los
## niveles con precio y efectos, y los sistemas leen su parámetro efectivo
## con effect() — así los futuros talentos pueden apilar sobre las mismas
## claves. Catálogo completo de diseño en docs/mejoras.md.

signal money_changed(total: int, delta: int)
signal day_started(day: int)
signal day_ended(day: int, summary: Dictionary)
signal upgrade_purchased(id: String, level: int)

## Los valores de "effects" son absolutos (pisan al anterior) salvo los
## sufijos _mult (multiplicador del valor base) y extra_ (aditivos).
const UPGRADE_CATALOG := {
	"despiece": {
		"name": "Kit de despiece",
		"levels": [
			{"price": 400, "desc": "Amoladora: lootear tarda 2.6 s (antes 4 s).",
				"effects": {"loot_time": 2.6}},
			{"price": 1200, "desc": "Cizalla hidráulica: lootear tarda 1.6 s.",
				"effects": {"loot_time": 1.6}},
			{"price": 3000, "desc": "Cortadora de plasma: 1.2 s y +1 parte por auto.",
				"effects": {"loot_time": 1.2, "loot_extra_parts": 1}},
		]},
	"electroiman": {
		"name": "Electroimán industrial",
		"levels": [
			{"price": 900, "desc": "Bobina reforzada: +50% de atracción, captura desde 1.4 m.",
				"effects": {"capture_distance": 1.4, "pull_accel_mult": 1.5}},
			{"price": 2200, "desc": "Bobina de obra pesada: atracción ×2.2, captura desde 1.9 m.",
				"effects": {"capture_distance": 1.9, "pull_accel_mult": 2.2}},
		]},
	"estabilizador": {
		"name": "Estabilizador giroscópico",
		"levels": [
			{"price": 800, "desc": "El imán se balancea mucho menos al mover la grúa.",
				"effects": {"sway_damping_mult": 2.2}},
			{"price": 2000, "desc": "Amortiguación activa: el péndulo casi ni se entera.",
				"effects": {"sway_damping_mult": 4.0}},
		]},
	"tractor": {
		"name": "Motor repotenciado",
		"levels": [
			{"price": 700, "desc": "La grúa móvil avanza un 40% más rápido.",
				"effects": {"tractor_speed_mult": 1.4}},
			{"price": 1800, "desc": "Turbo diésel: casi el doble de velocidad y empuje.",
				"effects": {"tractor_speed_mult": 1.9}},
		]},
	"prensa": {
		"name": "Pistones de alto tonelaje",
		"levels": [
			{"price": 1500, "desc": "Bloques 25% más valiosos y ciclo 30% más corto.",
				"effects": {"press_value_mult": 1.25, "press_cycle_mult": 0.7}},
			{"price": 3500, "desc": "Bloques 50% más valiosos y ciclo a la mitad.",
				"effects": {"press_value_mult": 1.5, "press_cycle_mult": 0.5}},
		]},
	"contrato": {
		"name": "Contrato ampliado",
		"levels": [
			{"price": 600, "desc": "La recepción entrega 2 autos más por día.",
				"effects": {"extra_cars_per_day": 2}},
			{"price": 1500, "desc": "4 autos más por día.",
				"effects": {"extra_cars_per_day": 4}},
			{"price": 3500, "desc": "7 autos más por día: jornada a patio lleno.",
				"effects": {"extra_cars_per_day": 7}},
		]},
	"linterna": {
		"name": "Linterna de mano",
		"levels": [
			{"price": 300, "desc": "Luz portátil para la noche (tecla T).",
				"effects": {"has_flashlight": 1}},
		]},
}

var money := 0
var day := 1
var day_active := true
var day_income := {"chatarra": 0, "piezas": 0, "bonos": 0}
var upgrades := {}  # id del catálogo -> nivel comprado (1-based)

## Hora del mundo (0-24). La jornada arranca a las 06:00 y el reloj solo
## corre con la jornada activa; un día completo dura seconds_per_game_day.
var hour := 6.0
var seconds_per_game_day := 1200.0


func _process(delta: float) -> void:
	if day_active:
		hour = wrapf(hour + delta * 24.0 / seconds_per_game_day, 0.0, 24.0)


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money, amount)


## Suma dinero imputándolo a una categoría del resumen de jornada.
func register_income(category: String, amount: int) -> void:
	day_income[category] = int(day_income.get(category, 0)) + amount
	add_money(amount)


func end_day() -> Dictionary:
	day_active = false
	var summary := day_income.duplicate()
	summary["total"] = int(day_income.chatarra) + int(day_income.piezas) + int(day_income.bonos)
	summary["day"] = day
	day_ended.emit(day, summary)
	return summary


func start_next_day() -> void:
	day += 1
	for category in day_income:
		day_income[category] = 0
	day_active = true
	hour = 6.0
	day_started.emit(day)


func is_night() -> bool:
	return hour < 6.0 or hour > 18.5


func clock_text() -> String:
	return "%02d:%02d" % [int(hour), int(fmod(hour, 1.0) * 60.0)]


func upgrade_level(id: String) -> int:
	return int(upgrades.get(id, 0))


## Compra el siguiente nivel de una mejora si hay dinero. Devuelve si compró.
func purchase(id: String) -> bool:
	var level := upgrade_level(id)
	var levels: Array = UPGRADE_CATALOG[id]["levels"]
	if level >= levels.size():
		return false
	var price := int(levels[level]["price"])
	if money < price:
		return false
	add_money(-price)
	upgrades[id] = level + 1
	upgrade_purchased.emit(id, level + 1)
	return true


## Valor efectivo de un parámetro según las mejoras compradas: el nivel más
## alto que declara la clave pisa a los anteriores. Sin compras devuelve el
## valor base que pasa el llamador.
func effect(key: String, default_value: float) -> float:
	var value := default_value
	for id in upgrades:
		var levels: Array = UPGRADE_CATALOG[id]["levels"]
		for i in upgrade_level(id):
			var fx: Dictionary = levels[i].get("effects", {})
			if fx.has(key):
				value = float(fx[key])
	return value
