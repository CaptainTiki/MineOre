# res://scripts/end_mission.gd
extends Control

@onready var victory_label = $VictoryPanel/VictoryLabel
@onready var enemies_label = $VictoryPanel/EnemiesLabel
@onready var duration_label = $VictoryPanel/DurationLabel
@onready var buildings_label = $VictoryPanel/BuildingsLabel
@onready var points_label = $VictoryPanel/PointsLabel
@onready var level_progress_bar = $VictoryPanel/LevelProgressBar
@onready var rank_label = $VictoryPanel/RankLabel
@onready var main_menu_button = $VictoryPanel/MainMenuButton

var mission_stats = {"enemies_killed": 0, "time_taken": 0.0, "buildings_destroyed": 0}
var current_points = 0
var total_points = 0
var current_level = 0
var points_to_next_level = 1000
var ranks = ["Junior Associate", "Associate", "Senior Associate", "Executive Miner"]
var current_rank = 0

func _ready():
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	current_points = GameState.player_xp
	current_level = GameState.player_level
	current_rank = min(GameState.player_level - 1, ranks.size() - 1)
	points_to_next_level = UnlockManager.get_xp_for_level(current_level + 1)
	if points_to_next_level == -1:
		points_to_next_level = 1000  # Fallback
	level_progress_bar.max_value = points_to_next_level
	level_progress_bar.value = current_points
	rank_label.text = "Next Rank: %s" % ranks[min(current_rank + 1, ranks.size() - 1)]

func display_results(stats: Dictionary, won: bool):
	mission_stats = stats
	victory_label.text = "Victory!" if won else "Defeat!"
	enemies_label.text = "Enemies Killed: %d" % stats.enemies_killed
	var minutes = int(stats.time_taken / 60)
	var seconds = int(stats.time_taken) % 60
	duration_label.text = "Mission Duration: %dm %ds" % [minutes, seconds]
	buildings_label.text = "Buildings Destroyed: %d" % stats.buildings_destroyed
	
	# Calculate bonus points
	total_points = (stats.enemies_killed * 10) + (int(stats.time_taken / 60) * 100) - (stats.buildings_destroyed * 50)
	points_label.text = "Bonus Points: %d" % total_points
	
	# Animate points
	animate_points()

func animate_points():
	var tween = create_tween()
	tween.tween_property(self, "current_points", current_points + total_points, 2.0)
	tween.tween_callback(_check_level_up)
	tween.tween_property(points_label, "text", "Bonus Points: %d" % total_points, 0.0)  # Update immediately
	tween.tween_property(level_progress_bar, "value", current_points + total_points, 2.0)

func _check_level_up():
	GameState.add_xp(total_points)
	current_level = GameState.player_level
	current_points = GameState.player_xp
	current_rank = min(current_level - 1, ranks.size() - 1)
	points_to_next_level = UnlockManager.get_xp_for_level(current_level + 1)
	if points_to_next_level == -1:
		points_to_next_level = 1000  # Fallback
	level_progress_bar.max_value = points_to_next_level
	level_progress_bar.value = current_points
	rank_label.text = "Next Rank: %s" % ranks[min(current_rank + 1, ranks.size() - 1)]
	print("Level: %d, XP: %d, Rank: %s" % [current_level, current_points, ranks[current_rank]])

func _on_main_menu_pressed():
	LevelManager.stop()
	get_tree().change_scene_to_file("res://StarMenu/star_menu.tscn")
