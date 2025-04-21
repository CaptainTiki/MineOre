extends Resource
class_name StarSystemResource

@export var system_name: String = "Unnamed System"
@export var star_scene: PackedScene  # The star’s scene file (e.g., star_yellow.tscn)
@export var planets: Array[PackedScene]  # Array of planet scene files
@export var difficulty: int = 1  # Difficulty level (e.g., 1-5)
@export var description: String = "A mysterious star system."
@export var locked: bool = true
