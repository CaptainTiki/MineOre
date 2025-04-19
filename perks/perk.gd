extends Resource
class_name Perk

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var normal_icon_path: String = ""
@export var pressed_icon_path: String = ""
@export var effects: Dictionary[String, float] = {}  # e.g., {"health": 1.05, "damage": 1.10}
@export var unlocked: bool = false
