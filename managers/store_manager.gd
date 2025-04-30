# res://scripts/store_manager.gd
extends Node

var purchased_items: Dictionary = {}

func get_available_items(level: int) -> Dictionary:
	var items = {
		"buildings": [],
		"perks": [],
		"curses": [],
		"player_unlocks": [],
		"planets": []
	}
	for unlock in UnlockManager.level_unlocks:
		if unlock.level <= level:
			for building in unlock.building_unlocks:
				if not is_purchased("building", building.id):
					items.buildings.append(building)
			for perk in unlock.perk_unlocks:
				if not is_purchased("perk", perk.id):
					items.perks.append(perk)
			for curse in unlock.curse_unlocks:
				if not is_purchased("curse", curse.id):
					items.curses.append(curse)
			for player_unlock in unlock.player_unlocks:
				if not is_purchased("player", player_unlock.id):
					items.player_unlocks.append(player_unlock)
			for planet in unlock.planet_unlocks:
				if not is_purchased("planet", planet.id):
					items.planets.append(planet)
	return items

func can_purchase(item_type: String, item_id: String, clp: int) -> bool:
	var key = item_type + ":" + item_id
	if purchased_items.has(key):
		return false
	for unlock in UnlockManager.level_unlocks:
		var unlocks = unlock.get(item_type + "_unlocks")
		if unlocks == null:
			print("Error: No %s_unlocks in unlock for level %d" % [item_type, unlock.level])
			continue
		for item in unlocks:
			if item.id == item_id:
				return clp >= item.clp_cost
	return false

func is_purchased(item_type: String, item_id: String) -> bool:
	var key = item_type + ":" + item_id
	return purchased_items.has(key)

func purchase_item(item_type: String, item_id: String) -> bool:
	var key = item_type + ":" + item_id
	if purchased_items.has(key):
		return false
	for unlock in UnlockManager.level_unlocks:
		var unlocks = unlock.get(item_type + "_unlocks")
		if unlocks == null:
			print("Error: No %s_unlocks in unlock for level %d" % [item_type, unlock.level])
			continue
		for item in unlocks:
			if item.id == item_id and GameState.clp >= item.clp_cost:
				GameState.clp -= item.clp_cost
				purchased_items[key] = true
				print("Purchased %s: %s, purchased_items: %s" % [item_type, item_id, purchased_items])
				match item_type:
					"building":
						UnlockManager.unlock_buildings([item_id])
					"perk":
						UnlockManager.unlock_perks([item_id])
					"curse":
						UnlockManager.unlock_curses([item_id])
					"player":
						UnlockManager.unlock_player_abilities([item_id])
					"planet":
						UnlockManager.unlock_planets([item_id])
				print("Purchased %s: %s for %d CLP" % [item_type, item_id, item.clp_cost])
				return true
			else:
				print("Cannot purchase %s: %s - CLP: %d, Cost: %d" % [item_type, item_id, GameState.clp, item.clp_cost])
	return false
