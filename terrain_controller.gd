extends Node3D
class_name TerrainController
 
## Holds the catalog of loaded terrain block and object scenes
@export var TerrainBlocks: Array[PackedScene] = []
@export var TerrainObjects: Array[PackedScene] = []
@export var TerrainScenery: Array[PackedScene] = []
 
## The set of terrain blocks and active obstacles in the viewport
var terrain_belt: Array[Node3D] = []
var active_obstacles: Array[Node3D] = []
var active_scenery: Array[Node3D] = []
 
## Flag to check if the game has ended
var game_over: bool = false
 
# =============================================================
# FITUR AKSELERASI DARI SKRIP PERTAMA
# =============================================================
@export var initial_velocity: float = 30.0
@export var max_velocity: float = 40.0
@export var acceleration: float = 0.75
var terrain_velocity: float = 0.0
# =============================================================
 
# === PENGATURAN DARI SKRIP KEDUA ===
@export var object_spawn_chance: float = 0.25
@export var num_terrain_blocks = 10

signal game_over_signal 

# =============================================================
# PENGATURAN KEMUNCULAN RINTANGAN DINAMIS
# =============================================================
var spawn_timer: float = 0.0
var spawn_interval: float = 2.0         # awal: tiap 2 detik (bisa diatur)
var elapsed_time: float = 0.0           # waktu total permainan berjalan (detik)
const MAX_GAME_TIME: float = 600.0      # 10 menit = 600 detik
const MIN_SPAWN_CHANCE: float = 0.5     # paling jarang
const MAX_SPAWN_CHANCE: float = 1.0     # paling sering
var allow_spawn: bool = false           # dikontrol dari Player.gd

# =============================================================
# PENGATURAN SCENERY
# =============================================================
@export var scenery_spawn_chance: float = 10     # seberapa sering muncul pohon
@export var scenery_min_distance: float = 25.0    # jarak minimal dari player
@export var scenery_max_distance: float = 500.0    # jarak maksimal dari player
@export var scenery_side_offset: float = 15.0     # jarak dari jalan utama ke kiri/kanan

var scenery_always_active: bool = true



func _ready() -> void:
	game_over = false

	# Atur kecepatan awal dari logika akselerasi
	terrain_velocity = initial_velocity

	_init_blocks(num_terrain_blocks)
	_load_terrain_scenes("res://terrain_objects",TerrainObjects)
	_load_scenery_scenes("res://terrain_scenery", TerrainScenery)


func _physics_process(delta: float) -> void:
	if game_over:
		return
	
	# LOGIKA AKSELERASI
	if terrain_velocity < max_velocity:
		terrain_velocity += acceleration * delta
	terrain_velocity = clamp(terrain_velocity, 0, max_velocity)
	
	# Hitung waktu total berjalan
	elapsed_time += delta
	
	# Naikkan probabilitas munculnya objek (0.1 → 1.0 selama 10 menit)
	var progress = clamp(elapsed_time / MAX_GAME_TIME, 0.1, 1.0)
	object_spawn_chance = lerp(MIN_SPAWN_CHANCE, MAX_SPAWN_CHANCE, progress)
	
	_progress_terrain(delta)
	_progress_obstacles(delta)
	_progress_scenery(delta)

	# 🚫 Hanya hentikan *spawn baru*, bukan gerakan
	if not allow_spawn:
		return


# Dipanggil oleh Player.gd saat game dimulai
func enable_spawning() -> void:
	allow_spawn = true

func _trigger_game_over() -> void:
	if game_over:
		return
	print("GAME OVER")
	game_over = true
	terrain_velocity = 0.0

	# === Stop all engine & effects sound ===
	var audio = get_node_or_null("/root/World/Audio")
	if audio and audio.has_method("stop_all_engine_sounds"):
		audio.stop_all_engine_sounds()

	# === Notify all obstacles ===
	emit_signal("game_over_signal")

	# === Show game over screen ===
	var player = get_node_or_null("/root/World/Player")
	if player and not player.game_is_over:
		player.show_game_over_ui()
 
# ======================================================================
# SEMUA FUNGSI LAINNYA DI AMBIL DARI SKRIP KEDUA ANDA (SUDAH BAGUS)
# TIDAK ADA PERUBAHAN DI BAWAH INI
# ======================================================================
 
func _progress_obstacles(delta: float) -> void:
	for obstacle in active_obstacles:
		if not is_instance_valid(obstacle):
			continue
		obstacle.position.z += terrain_velocity * delta
 
		var player = get_node_or_null("/root/World/Player")
		if player and player.has_method("receive_hit"):
			var hitbox = obstacle.get_node_or_null("Area3D")
			if hitbox and hitbox.get_overlapping_bodies().has(player):
				if obstacle.is_in_group("HealObjects"):
					player.receive_hit("heal", obstacle)
				elif obstacle.is_in_group("ObstacleObjects"):
					player.receive_hit("damage", obstacle)
 
func _progress_scenery(delta: float) -> void:
	for tree in active_scenery:
		if not is_instance_valid(tree):
			continue
		tree.position.z += terrain_velocity * delta

		# hapus kalau sudah lewat kamera
		if tree.position.z > 30.0:
			tree.queue_free()
	active_scenery = active_scenery.filter(is_instance_valid)


func _pick_random_block() -> PackedScene:
	return TerrainBlocks.pick_random()
 
func _pick_random_object() -> PackedScene:
	var candidates: Array = []
	for obj_scene in TerrainObjects:
		var obj = obj_scene.instantiate()
		print(obj.name," instantiated")
		if randf() < obj.spawn_chance:
			print(obj.name," is choosen")
			candidates.append(obj_scene)
		obj.queue_free()
	if candidates.is_empty():
		return null
	return candidates.pick_random()
 
func _init_blocks(number_of_blocks: int) -> void:
	for block_index in range(number_of_blocks):
		var block = _pick_random_block().instantiate()
		if block_index == 0:
			block.position.z = 0
		else:
			_append_to_far_edge(terrain_belt[block_index - 1], block)
		add_child(block)
		terrain_belt.append(block)
		if allow_spawn and randf() < object_spawn_chance:
			_spawn_object_on_block(block)



func _progress_terrain(delta: float) -> void:
	for block in terrain_belt:
		block.position.z += terrain_velocity * delta
 
	if terrain_belt.is_empty(): return
 
	if terrain_belt[0].position.z >= get_block_length(terrain_belt[0]):
		var last_terrain = terrain_belt[-1]
		var first_terrain = terrain_belt.pop_front()
 
		var block = _pick_random_block().instantiate()
		_append_to_far_edge(last_terrain, block)
		add_child(block)
		terrain_belt.append(block)
		first_terrain.queue_free()
		if allow_spawn and randf() < object_spawn_chance:
			_spawn_object_on_block(block)
		if (allow_spawn or scenery_always_active) and randf() < scenery_spawn_chance:
			_spawn_scenery(block)

 
func get_block_length(block: Node3D) -> float:
	# Try to find a MeshInstance3D inside the block, no matter what it’s named
	var mesh_instance := block.get_node_or_null("MeshInstance3D")
	if mesh_instance == null:
		# fallback: find the first MeshInstance3D anywhere in the children
		mesh_instance = block.find_child("", true, false) as MeshInstance3D
		if mesh_instance == null:
			push_error("No MeshInstance3D found in block: " + str(block.name))
			return 0.0
 
	var aabb = mesh_instance.mesh.get_aabb()
	return aabb.size.z * mesh_instance.scale.z
 
 
func _append_to_far_edge(target_block: Node3D, appending_block: Node3D) -> void:
	var target_len = get_block_length(target_block)
	appending_block.position.z = target_block.position.z - target_len
 
func _spawn_object_on_block(block: Node3D) -> void:
	var obj_scene = _pick_random_object()
	if obj_scene == null: 
		return
 
	var obj = obj_scene.instantiate()
 
	# Find the MeshInstance3D inside the terrain block
	var mesh_instance: MeshInstance3D = block.get_node_or_null("MeshInstance3D")
	if mesh_instance == null:
		mesh_instance = block.find_child("", true, false) as MeshInstance3D
		if mesh_instance == null:
			push_error("No MeshInstance3D found in block: " + str(block.name))
			return
 
	var aabb_block = mesh_instance.mesh.get_aabb()
	var width = aabb_block.size.x * mesh_instance.scale.x
	var length = aabb_block.size.z * mesh_instance.scale.z
 
	# Get spawn range info from object scene
	var spawn_x_range: Vector2 = obj.spawn_x_range
	var half_width = width / 2.0
	var min_x = lerp(-half_width, half_width, (spawn_x_range.x + 1.0) / 2.0)
	var max_x = lerp(-half_width, half_width, (spawn_x_range.y + 1.0) / 2.0)
 
	# Align object position with block
	obj.position = block.position
	obj.position.x += randf_range(min_x, max_x)
	obj.position.z -= length / 2.0
 
	add_child(obj)
	active_obstacles.append(obj)
 
func _spawn_scenery(block: Node3D) -> void:
	if TerrainScenery.is_empty():
		return
	var scene = TerrainScenery.pick_random()
	var tree = scene.instantiate()

	# posisi relatif terhadap player
	var player = get_node_or_null("/root/World/Player")
	if player:
		var side = sign(randf_range(-1.0, 1.0))
		var x_offset = scenery_side_offset * side + randf_range(-5.0, 5.0)
		var z_offset = -randf_range(scenery_min_distance, scenery_max_distance)
		tree.position = Vector3(player.position.x + x_offset, 0.0, player.position.z + z_offset)
	else:
		tree.position = block.position + Vector3(randf_range(-30, 30), 0, -randf_range(30, 200))

	add_child(tree)
	active_scenery.append(tree)


func _load_terrain_scenes(target_path: String, target_array: Array) -> void:
	var dir = DirAccess.open(target_path)
	if dir == null:
		push_error("Could not open directory: " + target_path)
		return
	for scene_path in dir.get_files():
		if scene_path.ends_with(".tscn"):
			print("Loading:", target_path + "/" + scene_path)
			target_array.append(load(target_path + "/" + scene_path))

func _load_scenery_scenes(target_path: String, target_array: Array) -> void:
	var dir = DirAccess.open(target_path)
	if dir == null:
		push_error("Could not open scenery directory: " + target_path)
		return
	for scene_path in dir.get_files():
		if scene_path.ends_with(".tscn"):
			print("Loading scenery:", target_path + "/" + scene_path)
			target_array.append(load(target_path + "/" + scene_path))
