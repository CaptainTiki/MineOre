extends Resource
class_name LevelUnlock

@export var level: int = 0  # The level at which these unlocks occur
@export var xp_amount: int = 0  # The XP required to reach this level
@export var building_unlocks: Array[String] = []  # Array of building names (e.g., "refinery")
@export var perk_unlocks: Array[String] = []  # Array of perk IDs (e.g., "player_speed_1")
@export var curse_unlocks: Array[String] = []  # Array of curse IDs (e.g., "slow_movement")
@export var player_unlocks: Array[String] = []  # Array of player unlocks (e.g., "weapon_laser")
@export var planet_unlocks: Array[String] = []  # Array of planet IDs (e.g., "earth")
