extends Node
## Estado global de la partida (autoload GameState): dinero, jornada y el
## desglose de ingresos del día según la fórmula visible del documento
## (chatarra + piezas + bonos − penalizaciones).

signal money_changed(total: int, delta: int)
signal day_started(day: int)
signal day_ended(day: int, summary: Dictionary)

var money := 0
var day := 1
var day_active := true
var day_income := {"chatarra": 0, "piezas": 0, "bonos": 0}


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
	day_started.emit(day)
