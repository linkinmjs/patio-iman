extends Label
## Contador de jornada y dinero del HUD global. Escucha al autoload GameState.


func _ready() -> void:
	_refresh()
	GameState.money_changed.connect(func(_total: int, _delta: int) -> void:
		_refresh())
	GameState.day_started.connect(func(_day: int) -> void:
		_refresh())


func _refresh() -> void:
	text = "Día %d · $ %d" % [GameState.day, GameState.money]
