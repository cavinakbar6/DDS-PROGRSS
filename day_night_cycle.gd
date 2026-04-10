extends DirectionalLight3D

## Waktu dalam detik untuk 1 siklus siang-malam penuh (Siang -> Siang lagi)
@export var cycle_duration: float = 60.0

# Base light energy saat siang
var max_energy: float = 1.0
var world_env: WorldEnvironment

func _ready() -> void:
	max_energy = light_energy
	world_env = get_parent().get_node_or_null("WorldEnvironment")

func _process(delta: float) -> void:
	# Rotasi matahari mengelilingi sumbu X
	# 360 derajat / cycle_duration
	var rotation_speed = deg_to_rad(360.0) / cycle_duration
	rotate_x(-rotation_speed * delta)
	
	# Ambil rotasi X saat ini (antara -PI dan PI)
	var rot_x = rotation.x
	
	var intensity_factor = 0.0
	
	if rot_x < 0.0:
		# Siang hari
		intensity_factor = sin(abs(rot_x)) 
		intensity_factor = clamp(intensity_factor * 1.5, 0.0, 1.0)
	else:
		# Malam hari
		intensity_factor = 0.0
		
	# Terapkan energi cahaya ke jalanan / dunia (dengan sedikit cahaya di malam hari agar tak pitch black)
	light_energy = max_energy * max(intensity_factor, 0.05)
	
	# Redupkan latar belakang langit (PENTING untuk membuat langit malam jadi hitam/gelap)
	if is_instance_valid(world_env) and world_env.environment != null:
		# Gunakan background_energy_multiplier untuk menggelapkan langit secara fisik
		world_env.environment.background_energy_multiplier = max(intensity_factor, 0.02)
		world_env.environment.ambient_light_energy = max(intensity_factor, 0.1)
