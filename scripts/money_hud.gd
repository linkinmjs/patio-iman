extends Label
## Contador de jornada, hora y dinero del HUD global. Se reconstruye solo
## cuando cambia algo visible (minuto del reloj, dinero o clima): armar el
## string por frame es la alocación caliente típica de un HUD.


var _last_minute := -1
var _last_money := 0
var _last_weather := ""


func _process(_delta: float) -> void:
	var minute := int(GameState.hour * 60.0)
	if minute == _last_minute and GameState.money == _last_money \
			and GameState.weather == _last_weather:
		return
	_last_minute = minute
	_last_money = GameState.money
	_last_weather = GameState.weather
	var status := ""
	if GameState.clock_stopped:
		status = " · andá a dormir"
	elif not GameState.can_earn():
		status = " · patio cerrado"
	text = "Día %d · %s · %s · $ %d%s" % [GameState.day, GameState.clock_text(),
			GameState.weather, GameState.money, status]
