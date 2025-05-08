# res://scripts/level_manager.gd
extends Node

signal start_day

var ground_size = Vector2(100, 100)

enum State { PLACING, DAY, NIGHT, WON, LOST }
var current_state = State.PLACING
var day_duration = 45.0
var day_timer = 0.0
var wave_count = 0
var total_waves = 2
var player_ore = 0
var planet_name = "alpha_one"
var has_hq = false
var night_start_time = 0.0
var mission_stats = {"ore_launched": 0, "time_taken": 0.0, "waves_survived": 0, "enemies_killed": 0, "buildings_destroyed": 0}
var enemy_count = 0

@onready var player = get_tree().get_root().get_node_or_null("Level/Player")
@onready var day_timer_label = get_tree().get_root().get_node_or_null("Level/UI/HBoxContainer/VBoxContainer2/DayTimerLabel")
@onready var wave_label = get_tree().get_root().get_node_or_null("Level/UI/HBoxContainer/VBoxContainer2/WaveLabel")
@onready var enemies_label = get_tree().get_root().get_node_or_null("Level/UI/HBoxContainer/VBoxContainer2/EnemiesLabel")
@onready var hq_health_label = get_tree().get_root().get_node_or_null("Level/UI/HBoxContainer/VBoxContainer/HQHealthLabel")
@onready var end_panel = get_tree().get_root().get_node_or_null("Level/UI/EndPanel")
@onready var end_label = get_tree().get_root().get_node_or_null("Level/UI/EndPanel/EndLabel")
@onready var restart_button = get_tree().get_root().get_node_or_null("Level/UI/EndPanel/RestartButton")
@onready var quit_button = get_tree().get_root().get_node_or_null("Level/UI/EndPanel/QuitButton")
@onready var ore_label = get_tree().get_root().get_node_or_null("Level/UI/HBoxContainer/VBoxContainer/OreLabel")
@onready var carried_ore_label = get_tree().get_root().get_node_or_null("Level/UI/HBoxContainer/VBoxContainer/CarriedOreLabel")
@onready var spawner_manager = get_tree().get_root().get_node_or_null("Level/SpawnerManager")
@onready var construction_menu = get_tree().get_root().get_node_or_null("Level/UI/ConstructionMenu")

func _ready():
	if player:
		player.ore_carried.connect(_on_ore_carried)
	else:
		push_error("Player node not found")
	if construction_menu:
		construction_menu.placement_failed.connect(_on_placement_failed)
	else:
		push_error("ConstructionMenu node not found")
	if end_panel:
		end_panel.visible = false
	else:
		push_error("EndPanel node not found")
	if restart_button:
		restart_button.connect("pressed", _on_restart_pressed)
	if quit_button:
		quit_button.connect("pressed", _on_quit_pressed)
	if spawner_manager:
		var max_waves = 0
		for spawner in spawner_manager.get_children():
			for wave_res in spawner.waves:
				max_waves = max(max_waves, wave_res.wave_counts.size())
		total_waves = max(total_waves, max_waves)
		spawner_manager.initialize_pool()
		await spawner_manager.pool_ready
	else:
		push_error("SpawnerManager not found")
	
	update_ui()

func _process(delta):
	match current_state:
		State.PLACING:
			pass
		State.DAY:
			day_timer -= delta
			mission_stats.time_taken += delta
			if day_timer <= 0:
				start_night()
		State.NIGHT:
			mission_stats.time_taken += delta
			var time_since_night = Time.get_ticks_msec() / 1000.0 - night_start_time
			enemy_count = 0
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if enemy.get("is_alive") == true:
					enemy_count += 1
			if time_since_night > 1.0:
				if enemy_count == 0 and wave_count > 0 and not spawner_manager.has_active_spawners():
					start_day_func()
		State.WON, State.LOST:
			pass
	
	if Input.is_action_just_pressed("leveldebug"):
		mission_stats.ore_launched = 30
		mission_stats.waves_survived = 2
		mission_stats.enemies_killed = spawner_manager.get_total_enemies_killed() + 10
		end_level(true)
	
	update_ui()

# ... (move other functions like assign_planet, _on_hq_placed, end_level, etc., with node path adjustments)
