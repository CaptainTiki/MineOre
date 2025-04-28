extends Node

var stats = {
	missions_completed = 0,
	ore_mined = 0,
	enemies_killed = 0,
	waves_survived = 0,
	clp_earned = 0
}

func track_mission_completion(ore_launched: int, enemies_killed: int, waves_survived: int):
	stats.missions_completed += 1
	stats.ore_mined += ore_launched
	stats.enemies_killed += enemies_killed
	stats.waves_survived += waves_survived
	# Assume CLP is tracked in GameState, but record it here too
	stats.clp_earned = GameState.clp
	print("Updated stats: ", stats)

func track_clp_earned(amount: int):
	stats.clp_earned += amount

func get_stats() -> Dictionary:
	return stats
