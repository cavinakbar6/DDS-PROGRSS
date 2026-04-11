extends DirectionalLight3D

@export var day_duration: float = 50.0
@export var transition_duration: float = 3.0
@export var night_duration: float = 50.0

var max_energy: float = 1.0
var world_env: WorldEnvironment
var time_passed: float = 0.0

var light_dimness: float = 0.2

func _ready() -> void:
	max_energy = light_energy
	world_env = get_parent().get_node_or_null("WorldEnvironment")

func _process(delta: float) -> void:
	time_passed += delta
	
	var total_cycle = day_duration + transition_duration + night_duration + transition_duration
	var t = fmod(time_passed, total_cycle)

	var intensity_factor = 0.0
	
	# === SIANG ===
	if t < day_duration:
		intensity_factor = 1.0
	
	# === SUNSET (terang → gelap) ===
	elif t < day_duration + transition_duration:
		var local_t = (t - day_duration) / transition_duration
		intensity_factor = lerp(1.0, light_dimness, local_t)
	
	# === MALAM ===
	elif t < day_duration + transition_duration + night_duration:
		intensity_factor = light_dimness
	
	# === SUNRISE (gelap → terang) ===
	else:
		var local_t = (t - (day_duration + transition_duration + night_duration)) / transition_duration
		intensity_factor = lerp(light_dimness, 1.0, local_t)
	
	# Terapkan ke cahaya (biar nggak pitch black)
	light_energy = max_energy * max(intensity_factor, light_dimness)
	
	# Environment (langit & ambient)
	if is_instance_valid(world_env) and world_env.environment != null:
		world_env.environment.background_energy_multiplier = max(intensity_factor, 0.02)
		world_env.environment.ambient_light_energy = max(intensity_factor, 0.1)
