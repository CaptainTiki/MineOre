# LevelUnlock.gd
extends Resource
class_name LevelUnlock

@export var level: int = 0  # The level at which this store tab unlocks
@export var xp_amount: int = 0  # The XP required to unlock this level/tab
@export var level_name: String = ""  # e.g., "Rookie", "Junior"
@export var building_unlocks: Array[Dictionary] = []  # e.g., [{"id": "refinery", "clp_cost": 50}]
@export var perk_unlocks: Array[Dictionary] = []  # e.g., [{"id": "player_speed_1", "clp_cost": 30}]
@export var curse_unlocks: Array[Dictionary] = []  # e.g., [{"id": "slow_movement", "clp_cost": 20}]
@export var player_unlocks: Array[Dictionary] = []  # e.g., [{"id": "weapon_laser", "clp_cost": 40}]
@export var planet_unlocks: Array[Dictionary] = []  # e.g., [{"id": "alpha_one", "clp_cost": 100}]
