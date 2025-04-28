# GameState.gd
extends Node

var player_level: int = 1
var player_xp: int = 0
var clp: int = 0  # Corporate Loyalty Points

func _ready():
	#clear purchased items on game load - we can fill this out later from the serializer
	StoreManager.purchased_items.clear()
	print("Cleared purchased items for debug")

func add_xp(amount: int):
	player_xp += amount
	while true:
		var next_level_xp = UnlockManager.get_xp_for_level(player_level + 1)
		if next_level_xp != -1 and player_xp >= next_level_xp:
			player_level += 1
			print("Leveled up to level ", player_level, " - New store tab unlocked!")
		else:
			break

func complete_mission(ore_launched: int, time_taken: float, waves_survived: int, enemies_killed: int):
	var clp_earned = ore_launched * 10
	clp_earned += int(1000 / max(time_taken, 1))
	clp_earned += waves_survived * 20
	clp_earned += enemies_killed * 5
	clp += clp_earned
	StatsManager.track_mission_completion(ore_launched, enemies_killed, waves_survived)
	print("Earned %d CLP for mission" % clp_earned)
