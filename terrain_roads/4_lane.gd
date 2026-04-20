extends Node3D

@onready var LeftPole: MeshInstance3D = $LeftLampPole/Light
@onready var RightPole: MeshInstance3D = $RightLampPole/Light

var day_night: Node = null

func _ready() -> void:
	day_night = get_node_or_null("/root/World/DirectionalLight3D")

func _process(delta: float) -> void:
	if day_night:
		if day_night.is_daytime():
			LeftPole.visible = false
			RightPole.visible = false
		else:
			LeftPole.visible = true
			RightPole.visible = true
