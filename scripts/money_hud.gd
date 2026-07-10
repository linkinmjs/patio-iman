extends Label
## Contador de dinero del HUD global. Escucha al autoload GameState.


func _ready() -> void:
	text = "$ %d" % GameState.money
	GameState.money_changed.connect(func(total: int, _delta: int) -> void:
		text = "$ %d" % total)
