# StoreManager.gd
extends Node

var purchased_items: Dictionary = {}  # e.g., {"building:refinery": true, "perk:player_speed_1": true}

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
			items.buildings.append_array(unlock.building_unlocks)
			items.perks.append_array(unlock.perk_unlocks)
			items.curses.append_array(unlock.curse_unlocks)
			items.player_unlocks.append_array(unlock.player_unlocks)
			items.planets.append_array(unlock.planet_unlocks)
	return items

func can_purchase(item_type: String, item_id: String, clp: int) -> bool:
	var key = item_type + ":" + item_id
	if purchased_items.has(key):
		return false  # Already purchased
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
