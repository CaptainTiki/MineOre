extends Node3D

class_name Planet

@export var planet_name: String = ""
@export var level_path: String = ""
@export var system_name: String = ""
@export var points_required: int = 0

func _ready():
	if not planet_name or not level_path or not system_name:
		print("Error: Planet ", name, " missing required data!")

func get_planet_data():
	return {
		"name": planet_name,
		"level_path": level_path,
		"system": system_name,
		"points_required": points_required
	}
