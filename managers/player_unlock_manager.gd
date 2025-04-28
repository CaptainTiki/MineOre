extends Node

var player_unlocks: Dictionary = {}  # id -> PlayerUnlock

func _ready():
	load_player_unlocks()

func load_player_unlocks():
	var dir = DirAccess.open("res://player_unlocks/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var unlock = load("res://player_unlocks/" + file_name) as Resource
				if unlock and unlock.id != "":
					if unlock.id in player_unlocks:
						push_error("Duplicate player unlock id: " + unlock.id)
					else:
						player_unlocks[unlock.id] = unlock
				else:
					push_warning("Invalid player unlock file: " + file_name)
			file_name = dir.get_next()
	else:
		push_error("Failed to open res://player_unlocks/")

func is_ability_unlocked(ability_id: String) -> bool:
	if ability_id in player_unlocks:
		return player_unlocks[ability_id].unlocked
	return false

func unlock_ability(ability_id: String):
	if ability_id in player_unlocks:
		player_unlocks[ability_id].unlocked = true
		print("Player ability unlocked: ", ability_id)
	else:
		push_error("Player ability not found: " + ability_id)

func has_ability(ability_id: String) -> bool:
	return ability_id in player_unlocks
