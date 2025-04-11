extends Node3D
class_name StarSystem

@export var system_name: String = ""
@export var difficulty: String = ""
@export var points_required: int = 0
@export var planet_scenes: Array[PackedScene] = []

func _ready():
	if not system_name or not planet_scenes:
		print("Error: System ", name, " missing required data!")

func get_system_data():
	return {
		"name": system_name,
		"difficulty": difficulty,
		"points_required": points_required,
		"planets": planet_scenes
	}
