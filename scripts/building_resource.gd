class_name BuildingResource extends Resource

@export var building_name: String
@export var display_name: String
@export var scene_path: String
@export var category: String
@export var build_cost: int
@export var construction_time: float = 0.0  # Time in seconds to construct
@export var base_health: float
@export var grid_extents: Vector2i
@export var is_unique: bool  # Can only be built once in a level
@export var is_locked: bool
@export var icon: Texture2D
@export var tags: Array[String]
@export var custom_script_path: String
@export var upgrade_to: BuildingResource
@export var upgrade_cost: int
@export var dependencies: Array[String]  # Required buildings to unlock this one
