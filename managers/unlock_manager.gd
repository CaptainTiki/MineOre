# res://scripts/unlock_manager.gd
extends Node

var level_unlocks: Array[LevelUnlock] = []
var level_unlocks_dict: Dictionary = {}

func _ready():
	load_level_unlocks()

func load_level_unlocks():
	var dir = DirAccess.open("res://level_unlocks/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var unlock = load("res://level_unlocks/" + file_name) as LevelUnlock
				if unlock:
					level_unlocks.append(unlock)
			file_name = dir.get_next()
		level_unlocks.sort_custom(func(a, b): return a.level < b.level)
		for unlock in level_unlocks:
			if unlock.level in level_unlocks_dict:
				push_error("Duplicate level: " + str(unlock.level))
			else:
				level_unlocks_dict[unlock.level] = unlock
	else:
		push_error("Failed to open level_unlocks directory")

func get_xp_for_level(level: int) -> int:
	if level in level_unlocks_dict:
		return level_unlocks_dict[level].xp_amount
	return -1

func get_next_unlocks(current_level: int) -> Dictionary:
	var next_level = current_level + 1
	if next_level in level_unlocks_dict:
		var unlock = level_unlocks_dict[next_level]
		return {
			"level": unlock.level,
			"level_name": unlock.level_name,
			"xp_required": unlock.xp_amount,
			"building_unlocks": unlock.building_unlocks,
			"perk_unlocks": unlock.perk_unlocks,
			"curse_unlocks": unlock.curse_unlocks,
			"player_unlocks": unlock.player_unlocks,
			"planet_unlocks": unlock.planet_unlocks
		}
	return {}

func unlock_buildings(buildings: Array[String]):
	for building in buildings:
		if building not in BuildingsManager.globally_unlocked_buildings:
			BuildingsManager.globally_unlocked_buildings.append(building)
			if building in BuildingsManager.locked_buildings:
				BuildingsManager.locked_buildings.erase(building)
			print("Unlocked building: %s" % building)

func unlock_perks(perks: Array[String]):
	for perk in perks:
		if not PerksManager.is_perk_unlocked(perk):
			PerksManager.unlock_perk(perk)
			print("Unlocked perk: %s" % perk)

func unlock_curses(curses: Array[String]):
	for curse in curses:
		if not CurseManager.is_curse_unlocked(curse):
			CurseManager.unlock_curse(curse)
			print("Unlocked curse: %s" % curse)

func unlock_player_abilities(abilities: Array[String]):
	for ability in abilities:
		if not PlayerUnlockManager.is_ability_unlocked(ability):
			PlayerUnlockManager.unlock_ability(ability)
			print("Unlocked player ability: %s" % ability)

func unlock_planets(planets: Array[String]):
	for planet in planets:
		if not PlanetManager.is_planet_unlocked(planet):
			PlanetManager.unlock_planet(planet)
			print("Unlocked planet: %s" % planet)
