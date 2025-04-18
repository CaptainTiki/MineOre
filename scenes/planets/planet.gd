extends Area3D
class_name Planet

@export var planet_name: String = ""
@export var points_required: int = 0
@export var level_path: String = ""

@export_category("Mission Data")
@export var planet_type: String = ""
@export var waves: int = 0
@export var resistance: String = ""

func _ready():
	if not planet_name:
		planet_name = name
	if not level_path:
		print("Warning: Planet '%s' has no level_path" % planet_name)

func get_planet_data() -> Dictionary:
	return {
		"name": planet_name,
		"points_required": points_required,
		"level_path": level_path,
		"planet_type": planet_type,
		"waves": waves,
		"resistance": resistance
	}
