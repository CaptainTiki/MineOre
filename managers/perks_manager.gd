# res://scripts/perks_manager.gd
extends Node

# Dictionary to store all perks by their id
var perks: Dictionary[String, Perk] = {}  # id -> Perk

# Array to store the ids of active perks
var active_perk_ids: Array = []

func _ready():
	load_perks()

func load_perks():
	var dir = DirAccess.open("res://perks/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var perk = load("res://perks/" + file_name) as Perk
				if perk and perk.id != "":
					if perk.id in perks:
						push_error("Duplicate perk id: " + perk.id)
					else:
						perks[perk.id] = perk
				else:
					push_warning("Invalid perk file: " + file_name)
			file_name = dir.get_next()
	else:
		push_error("Failed to open res://perks/")

func set_active_perks(perk_ids: Array):
	# Check if all perk_ids are unlocked and within the limit (e.g., 3)
	for pid in perk_ids:
		if pid not in perks or not perks[pid].unlocked:
			push_error("Cannot activate locked or non-existent perk: " + pid)
			return
	if perk_ids.size() > 3:
		push_error("Cannot activate more than 3 perks")
		return
	active_perk_ids = perk_ids

func get_modified_stat(base_value: float, stat_name: String) -> float:
	var total_multiplier = 1.0
	for pid in active_perk_ids:
		var perk = perks[pid]
		if stat_name in perk.effects:
			total_multiplier *= perk.effects[stat_name]
	return base_value * total_multiplier

func unlock_perk(perk_id: String):
	if perk_id in perks:
		perks[perk_id].unlocked = true
	else:
		push_error("Perk not found: " + perk_id)

func is_perk_unlocked(perk_id: String) -> bool:
	if perk_id in perks:
		return perks[perk_id].unlocked
	return false

func get_all_perks() -> Array:
	return perks.values()

func get_unlocked_perks() -> Array:
	var unlocked = []
	for perk in perks.values():
		if perk.unlocked:
			unlocked.append(perk)
	return unlocked

func get_locked_perks() -> Array:
	var locked = []
	for perk in perks.values():
		if not perk.unlocked:
			locked.append(perk)
	return locked

func get_perk_by_id(perk_id: String) -> Perk:
	return perks.get(perk_id, null)
