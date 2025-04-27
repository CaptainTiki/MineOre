extends Node

var player_level: int = 1
var player_xp: int = 0

func _ready():
	# Apply unlocks for the initial level
	UnlockManager.set_unlocks_up_to_level(player_level)

func add_xp(amount: int):
	player_xp += amount
	while true:
		var next_level_xp = UnlockManager.get_xp_for_level(player_level + 1)
		if next_level_xp != -1 and player_xp >= next_level_xp:
			player_level += 1
			UnlockManager.unlock_level(player_level)
			print("Leveled up to level ", player_level)
		else:
			break
