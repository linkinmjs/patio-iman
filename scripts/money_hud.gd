extends Label
## Contador de jornada, hora y dinero del HUD global (lee GameState por
## frame porque el reloj avanza continuamente). Avisa cuando el patio está
## fuera de la ventana productiva.


func _process(_delta: float) -> void:
	var status := ""
	if GameState.clock_stopped:
		status = " · andá a dormir"
	elif not GameState.can_earn():
		status = " · patio cerrado"
	text = "Día %d · %s · %s · $ %d%s" % [GameState.day, GameState.clock_text(),
			GameState.weather, GameState.money, status]
