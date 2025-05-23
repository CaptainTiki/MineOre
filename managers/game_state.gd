# res://scripts/game_state.gd
extends Node

var player_level: int = 1
var player_xp: int = 0
var player_rank: int = 0
var clp: int = 0  # Corporate Loyalty Points
var completed_planets: Array[String] = []  # List of completed planet names
var planet_completion_points: int = 0  # Points for unlocking new systems/planets
var planet_stats: Dictionary = {}  # planet_name -> {play_count, shortest_time, max_waves, high_score}

func _ready():
	# Clear purchased items on game load
	StoreManager.purchased_items.clear()
	print("Cleared purchased items for debug")

func add_xp(amount: int):
	player_xp += amount
	while true:
		var next_level_xp = UnlockManager.get_xp_for_level(player_level + 1)
		if next_level_xp != -1 and player_xp >= next_level_xp:
			player_level += 1
			player_rank = min(player_level - 1, 3)  # Max rank index is 3 (Executive Miner)
			print("Leveled up to level %d - New store tab unlocked! Rank: %d" % [player_level, player_rank])
		else:
			break

func update_level(level: int, points: int, rank: int):
	player_level = level
	player_xp = points
	player_rank = rank
	print("Updated level: %d, XP: %d, Rank: %d" % [level, points, rank])

func complete_mission(ore_launched: int, time_taken: float, waves_survived: int, enemies_killed: int) -> Dictionary:
	var clp_earned = ore_launched * 10
	clp_earned += int(1000 / max(time_taken, 1))
	clp_earned += waves_survived * 20
	clp_earned += enemies_killed * 5
	var xp_earned = ore_launched * 5 + waves_survived * 10 + enemies_killed * 2
	return {"clp": clp_earned, "xp": xp_earned}

func complete_planet(planet_name: String, success: bool, ore_launched: int, time_taken: float, waves_survived: int, enemies_killed: int, bonus_points: int):
	var rewards = complete_mission(ore_launched, time_taken, waves_survived, enemies_killed)
	
	# Update planet stats
	if not planet_stats.has(planet_name):
		planet_stats[planet_name] = {
			"play_count": 0,
			"shortest_time": -1.0,  # -1 means no completion
			"max_waves": 0,
			"high_score": 0
		}
	planet_stats[planet_name].play_count += 1
	if success:
		if planet_name in completed_planets:
			print("Planet %s already completed" % planet_name)
		else:
			completed_planets.append(planet_name)
			planet_completion_points += 1
			PlanetManager.unlock_planet(planet_name)
		# Update shortest time (only if completed)
		if planet_stats[planet_name].shortest_time == -1.0 or time_taken < planet_stats[planet_name].shortest_time:
			planet_stats[planet_name].shortest_time = time_taken
		planet_stats[planet_name].max_waves = max(planet_stats[planet_name].max_waves, waves_survived)
		planet_stats[planet_name].high_score = max(planet_stats[planet_name].high_score, bonus_points)
	else:
		# Partial rewards for failure (50% CLP and XP)
		rewards.clp = int(rewards.clp * 0.5)
		rewards.xp = int(rewards.xp * 0.5)
	
	# Apply rewards
	clp += rewards.clp
	add_xp(rewards.xp)
	StatsManager.track_mission_completion(ore_launched, enemies_killed, waves_survived)
	print("Planet %s %s: Earned %d CLP, %d XP, Total points: %d" % [
		planet_name, "completed" if success else "failed", rewards.clp, rewards.xp, planet_completion_points
	])
