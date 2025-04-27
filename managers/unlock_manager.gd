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
		# Sort by level
		level_unlocks.sort_custom(func(a, b): return a.level < b.level)
		# Create dictionary for quick access and check for duplicates
		for unlock in level_unlocks:
			if unlock.level in level_unlocks_dict:
				push_error("Duplicate level: " + str(unlock.level))
			else:
				level_unlocks_dict[unlock.level] = unlock
	else:
		push_error("Failed to open level_unlocks directory")

func unlock_level(level: int):
	if level in level_unlocks_dict:
		var unlock = level_unlocks_dict[level]
		unlock_buildings(unlock.building_unlocks)
		unlock_perks(unlock.perk_unlocks)
		unlock_curses(unlock.curse_unlocks)
		unlock_player_abilities(unlock.player_unlocks)
		unlock_planets(unlock.planet_unlocks)
	else:
		push_warning("Level not found: " + str(level))

func set_unlocks_up_to_level(level: int):
	for l in range(1, level + 1):
		unlock_level(l)

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
			print("Unlocked building: ", building)

func unlock_perks(perks: Array[String]):
	for perk in perks:
		if not PerksManager.is_perk_unlocked(perk):
			PerksManager.unlock_perk(perk)
			print("Unlocked perk: ", perk)

func unlock_curses(curses: Array[String]):
	for curse in curses:
		pass

func unlock_player_abilities(abilities: Array[String]):
	for ability in abilities:
		pass

func unlock_planets(planets: Array[String]):
	for planet in planets:
		pass
