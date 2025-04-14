extends Node

var unlocked_buildings = ["hq", "ore_mine", "turret"]
var building_configs = {
	"hq": {"scene": "res://scenes/buildings/headquarters.tscn", "category": "unique", "cost": 0, "unique": true},
	"research": {"scene": "res://scenes/buildings/research_building.tscn", "category": "unique", "cost": 5, "unique": true},
	"ore_mine": {"scene": "res://scenes/buildings/ore_mine.tscn", "category": "ore", "cost": 5},
	"silo": {"scene": "res://scenes/buildings/silo.tscn", "category": "ore", "cost": 10},
	"turret": {"scene": "res://scenes/buildings/turret.tscn", "category": "defenses", "cost": 2},
	"cannon": {"scene": "res://scenes/buildings/cannon.tscn", "category": "defenses", "cost": 8},
	"launch_pad": {"scene": "res://scenes/buildings/launch_pad.tscn", "category": "unique", "cost": 1, "unique": true}
}
var research_options = {
	"silo": {"ore_cost": 10, "description": "Unlocks Silo: Stores +50 ore"},
	"cannon": {"ore_cost": 15, "description": "Unlocks Cannon: Turret with explosive bullets"},
	"launch_pad": {"ore_cost": 5, "description": "Unlocks Launch Pad: Send ore to orbit to win"}
}

func is_building_unlocked(building: String) -> bool:
	return building in unlocked_buildings

func unlock_building(building: String):
	if building in research_options and building not in unlocked_buildings:
		unlocked_buildings.append(building)
		print("Unlocked building: ", building)
	else:
		print("Building ", building, " already unlocked or invalid")

func get_research_options() -> Dictionary:
	return research_options

func get_ore_cost(building: String) -> int:
	return research_options.get(building, {}).get("ore_cost", 0)
