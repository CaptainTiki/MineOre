extends Node

# Singleton: Add to Project > AutoLoad as "Perks"

# Available perks with their effects
var perk_definitions = {
	"building_health": {"multiplier": 1.05, "description": "Buildings have 5% more health"},
	"turret_rotation_speed": {"multiplier": 1.25, "description": "Turrets rotate 25% faster"},
	"turret_damage": {"multiplier": 1.20, "description": "Turrets deal 20% more damage"},
	"turret_fire_rate": {"multiplier": 0.10, "description": "Turrets shoot 25% faster (lower interval)"},
	"player_movement_speed": {"multiplier": 1.15, "description": "Player moves 15% faster"}
}

# Active perks chosen by player
var active_perks = ["turret_fire_rate"]

func set_active_perks(perks: Array):
	active_perks = perks
	print("Active perks set: ", active_perks)

func get_modified_stat(base_value: float, stat_name: String) -> float:
	var value = base_value
	for perk in active_perks:
		if perk in perk_definitions and stat_name in perk:
			value *= perk_definitions[perk]["multiplier"]
	return value

func get_perk_description(perk_name: String) -> String:
	return perk_definitions.get(perk_name, {}).get("description", "No description")
