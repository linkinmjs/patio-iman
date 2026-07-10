extends Node
## Estado global de la partida (autoload GameState). Por ahora solo dinero;
## acá van a vivir turnos, pureza y progresión cuando lleguen esos sistemas.

signal money_changed(total: int, delta: int)

var money := 0


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money, amount)
