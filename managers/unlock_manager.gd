extends Node

# Preload the level unlocks resource
var level_unlocks = preload("res://LevelUnlocks.tres").level_data

# Get all unlocked items based on player's XP
func get_unlocked_items(player_xp: int) -> Dictionary:
	var unlocked = {"planets": [], "perks": []}
	var current_level = 1
	
	# Find the highest level reached
	for level in level_unlocks.keys():
		if player_xp >= level_unlocks[level].xp_threshold:
			current_level = level
		else:
			break
	
	# Collect all unlocks up to the current level
	for l in range(1, current_level + 1):
		for unlock in level_unlocks[l].unlocks:
			match unlock.type:
				"planet":
					unlocked.planets.append(unlock.id)
				"perk":
					unlocked.perks.append(unlock.id)
	
	return unlocked

# Apply the unlocks to the game
func apply_unlocks(unlocked: Dictionary) -> void:
	for planet in unlocked.planets:
		unlock_planet(planet)
	for perk in unlocked.perks:
		unlock_perk(perk)

func unlock_planet(planet_id: String) -> void:
	# Example: Make planet selectable in the star map
	print("Unlocked planet: ", planet_id)

func unlock_perk(perk_id: String) -> void:
	# Example: Add perk to player's available perks
	print("Unlocked perk: ", perk_id)

# Get the next unlock for display
func get_next_unlock(player_xp: int) -> Array:
	for level in level_unlocks.keys():
		if player_xp < level_unlocks[level].xp_threshold:
			return level_unlocks[level].unlocks
	return []  # No more unlocks
