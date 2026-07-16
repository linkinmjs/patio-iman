extends Label
## Contador de jornada, hora y dinero del HUD global (lee GameState por frame
## porque el reloj avanza continuamente).


func _process(_delta: float) -> void:
	text = "Día %d · %s · $ %d" % [GameState.day, GameState.clock_text(), GameState.money]
