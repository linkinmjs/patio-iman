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
signal trophy_collected(id: String)

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
	"revolver": {
		"name": "Revólver .38 gastado",
		"levels": [
			{"price": 1200, "desc": "G lo saca: click dispara, click der. apunta, R recarga bala a bala.",
				"effects": {"has_gun": 1}},
		]},
	"balas": {
		"name": "Caja de balas .38",
		"requires": "revolver",
		"repeatable": true,
		"price": 150,
		"gives_ammo": 12,
		"desc": "12 balas. Para el tiro al blanco... o para dormir más tranquilo."},
}

## Clima del día: se sortea al despertar. Sus parámetros modulan visuales
## y física en quien los lea: "sun" multiplica la luz, "fog_add" suma
## niebla, "grey" desatura el cielo, "wind" excita el péndulo del imán y
## "rain" activa las partículas de lluvia.
const WEATHERS := {
	"despejado": {"sun": 1.0, "fog_add": 0.0, "grey": 0.0, "wind": 0.0, "rain": 0.0},
	"nublado": {"sun": 0.45, "fog_add": 0.002, "grey": 0.75, "wind": 0.2, "rain": 0.0},
	"niebla": {"sun": 0.55, "fog_add": 0.028, "grey": 0.55, "wind": 0.0, "rain": 0.0},
	"lluvia": {"sun": 0.35, "fog_add": 0.008, "grey": 0.9, "wind": 0.5, "rain": 1.0},
	"ventoso": {"sun": 0.85, "fog_add": 0.0, "grey": 0.2, "wind": 1.0, "rain": 0.0},
}
## Bolsa de sorteo: repetir un clima lo hace más probable.
const WEATHER_POOL := ["despejado", "despejado", "despejado", "nublado", "nublado",
		"niebla", "lluvia", "ventoso"]

var money := 0
var day := 1
var day_active := true
var day_income := {"chatarra": 0, "piezas": 0, "bonos": 0}
var weather := "despejado"
var upgrades := {}  # id del catálogo -> nivel comprado (1-based)
var ammo := 0  # balas del revólver (consumible de la tienda)
var trophies := {}  # colección: trophy_id -> nombre visible

## Hora del mundo (0-24). La jornada arranca a las 09:00 al despertar y el
## reloj corre hasta congelarse a las 03:00: ahí la única salida es dormir
## en la casilla. Desde la medianoche el patio no genera ingresos (las
## ventas y la recepción esperan a la mañana); todo configurable hasta
## desarrollar el lore. Un día completo dura seconds_per_game_day.
var hour := 9.0
var seconds_per_game_day := 1200.0
var day_start_hour := 9.0   ## hora a la que se despierta
var clock_stop_hour := 3.0  ## el reloj se congela acá hasta ir a dormir
var earn_from_hour := 9.0   ## ventana productiva: de acá a la medianoche
var sleep_from_hour := 22.0 ## desde esta hora se puede ir a dormir
var clock_stopped := false


func _ready() -> void:
	weather = WEATHER_POOL[randi() % WEATHER_POOL.size()]


func _process(delta: float) -> void:
	if not day_active or clock_stopped:
		return
	var prev := hour
	hour = wrapf(hour + delta * 24.0 / seconds_per_game_day, 0.0, 24.0)
	# Madrugada: al cruzar la hora límite el reloj se planta.
	if prev < clock_stop_hour and hour >= clock_stop_hour and hour < 12.0:
		hour = clock_stop_hour
		clock_stopped = true


## Ventana productiva: de la mañana a la medianoche. De madrugada se puede
## seguir trabajando (dejar todo preparado) pero nada paga ni entran autos.
func can_earn() -> bool:
	return day_active and hour >= earn_from_hour


func can_sleep() -> bool:
	return day_active and (hour >= sleep_from_hour or hour <= clock_stop_hour)


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
	hour = day_start_hour
	clock_stopped = false
	weather = WEATHER_POOL[randi() % WEATHER_POOL.size()]
	day_started.emit(day)


func weather_value(key: String) -> float:
	return float(WEATHERS[weather].get(key, 0.0))


## Suma un trofeo a la colección (una sola vez por id); el estante de la
## casilla la refleja. Los trofeos cuentan historias, no pagan dinero.
func collect_trophy(id: String, display_name: String) -> void:
	if trophies.has(id):
		return
	trophies[id] = display_name
	trophy_collected.emit(id)


func is_night() -> bool:
	return hour < 6.0 or hour > 18.5


func clock_text() -> String:
	return "%02d:%02d" % [int(hour), int(fmod(hour, 1.0) * 60.0)]


func upgrade_level(id: String) -> int:
	return int(upgrades.get(id, 0))


## Compra el siguiente nivel de una mejora (o un consumible repetible) si
## hay dinero. Devuelve si compró.
func purchase(id: String) -> bool:
	var info: Dictionary = UPGRADE_CATALOG[id]
	if info.get("repeatable", false):
		var cost := int(info["price"])
		if money < cost:
			return false
		add_money(-cost)
		ammo += int(info.get("gives_ammo", 0))
		upgrade_purchased.emit(id, upgrade_level(id))
		return true
	var level := upgrade_level(id)
	var levels: Array = info["levels"]
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
