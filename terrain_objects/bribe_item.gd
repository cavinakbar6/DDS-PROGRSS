extends Node3D

@export var spawn_chance: float = 0.30
@export var spawn_x_range: Vector2 = Vector2(-1, 1)

@onready var star_top = $StarTop
@onready var star_bottom = $StarBottom
var time_passed: float = 0.0

func _ready() -> void:
	add_to_group("BribeObjects")

func _process(delta: float) -> void:
	time_passed += delta
	
	# Putar bintang kayak GTA SA
	if is_instance_valid(star_top):
		star_top.rotate_y(3.0 * delta)
		star_top.position.y = 1.0 + sin(time_passed * 4.0) * 0.25
	
	if is_instance_valid(star_bottom):
		star_bottom.rotate_y(3.0 * delta)
		star_bottom.position.y = 1.0 + sin(time_passed * 4.0) * 0.25
