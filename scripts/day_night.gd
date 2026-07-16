extends Node
## Ciclo visual de día y noche: lee GameState.hour y acomoda el sol, el
## cielo y (vía el sky) la luz ambiente. Amanecer 06:00, ocaso 18:00; de
## noche el patio queda a merced de faroles, linterna y luces de grúa.

@onready var sun: DirectionalLight3D = get_node("../Sol")
@onready var world_env: WorldEnvironment = get_node("../WorldEnvironment")


func _process(_delta: float) -> void:
	var t: float = (GameState.hour - 6.0) / 12.0  # 0 amanecer, 0.5 mediodía, 1 ocaso
	var elev := sin(t * PI)  # altura del sol; negativa de noche
	var daylight := clampf(elev, 0.0, 1.0)
	var twilight := clampf(1.0 - absf(elev) * 4.0, 0.0, 1.0)  # sol cerca del horizonte

	sun.rotation_degrees = Vector3(-8.0 - 70.0 * daylight, -35.0, 0.0)
	sun.light_energy = lerpf(0.02, 1.3, daylight)
	sun.light_color = Color(1.0, 0.5, 0.3).lerp(
			Color(1.0, 0.88, 0.72), clampf(daylight * 2.0, 0.0, 1.0))

	var sky: ProceduralSkyMaterial = world_env.environment.sky.sky_material
	sky.sky_top_color = Color(0.015, 0.02, 0.05).lerp(Color(0.25, 0.38, 0.6), daylight)
	var horizon := Color(0.04, 0.05, 0.09).lerp(Color(0.72, 0.8, 0.9), daylight)
	horizon = horizon.lerp(Color(0.92, 0.55, 0.32), twilight)
	sky.sky_horizon_color = horizon
	sky.ground_horizon_color = horizon
