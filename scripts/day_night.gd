extends Node
## Ciclo visual de día y noche: lee GameState.hour y acomoda el sol, el
## cielo, la luz ambiente y la niebla. Amanecer 06:00, ocaso 18:00. De
## noche la oscuridad es real: la niebla cierra el rango de visión y solo
## se ve lo que alumbran la linterna, los faroles y las grúas.

@export var night_fog_density := 0.06  ## corta la visión a ~20 m de noche
@export var day_fog_density := 0.001

@export var sun: DirectionalLight3D
@export var world_env: WorldEnvironment
@export var rain: GPUParticles3D

## Tocar el ProceduralSkyMaterial regenera la radiance del cielo, así que
## sus colores se actualizan a 10 Hz; la luz del sol y la niebla, que son
## baratas, siguen por frame.
const SKY_UPDATE_INTERVAL := 0.1

var _sky_cooldown := 0.0
var _player: Player = null  # cacheado para que la lluvia lo siga


func _ready() -> void:
	world_env.environment.fog_enabled = true


func _process(delta: float) -> void:
	var t: float = (GameState.hour - 6.0) / 12.0  # 0 amanecer, 0.5 mediodía, 1 ocaso
	var elev := sin(t * PI)  # altura del sol; negativa de noche
	var daylight := clampf(elev, 0.0, 1.0)
	var twilight := clampf(1.0 - absf(elev) * 4.0, 0.0, 1.0)  # sol cerca del horizonte
	var grey: float = GameState.weather_value("grey")

	sun.rotation_degrees = Vector3(-8.0 - 70.0 * daylight, -35.0, 0.0)
	sun.light_energy = lerpf(0.005, 1.3, daylight) * GameState.weather_value("sun")
	sun.light_color = Color(1.0, 0.5, 0.3).lerp(
			Color(1.0, 0.88, 0.72), clampf(daylight * 2.0, 0.0, 1.0))

	var horizon := Color(0.02, 0.025, 0.05).lerp(Color(0.72, 0.8, 0.9), daylight)
	horizon = horizon.lerp(Color(0.92, 0.55, 0.32), twilight) \
			.lerp(Color(0.42, 0.44, 0.47) * maxf(daylight, 0.03), grey * 0.8)

	_sky_cooldown -= delta
	if _sky_cooldown <= 0.0:
		_sky_cooldown = SKY_UPDATE_INTERVAL
		# Cielo por hora, desaturado hacia gris plomo según el clima del día.
		var grey_sky := Color(0.42, 0.44, 0.47) * maxf(daylight, 0.03)
		var sky: ProceduralSkyMaterial = world_env.environment.sky.sky_material
		sky.sky_top_color = Color(0.008, 0.01, 0.03).lerp(Color(0.25, 0.38, 0.6), daylight) \
				.lerp(grey_sky, grey)
		sky.sky_horizon_color = horizon
		sky.ground_horizon_color = horizon

	# Oscuridad con cuerpo: de noche la niebla negra se traga el patio;
	# el clima puede sumarle niebla o llovizna encima.
	var env: Environment = world_env.environment
	env.fog_density = lerpf(night_fog_density, day_fog_density, daylight) \
			+ GameState.weather_value("fog_add")
	env.fog_light_color = horizon.darkened(0.35)

	var raining := GameState.weather_value("rain") > 0.0
	rain.emitting = raining
	if raining:
		if _player == null:
			_player = get_tree().get_first_node_in_group("player") as Player
		if _player:
			rain.global_position = _player.global_position + Vector3(0, 9, 0)
