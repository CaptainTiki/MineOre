# res://scripts/level.gd
extends Node3D

signal start_day

@onready var player = $Player
@onready var camera = $Camera
@onready var day_timer_label = $UI/HBoxContainer/VBoxContainer2/DayTimerLabel
@onready var wave_label = $UI/HBoxContainer/VBoxContainer2/WaveLabel
@onready var enemies_label = $UI/HBoxContainer/VBoxContainer2/EnemiesLabel
@onready var hq_health_label = $UI/HBoxContainer/VBoxContainer/HQHealthLabel
@onready var end_panel = $UI/EndPanel
@onready var end_label = $UI/EndPanel/EndLabel
@onready var restart_button = $UI/EndPanel/RestartButton
@onready var quit_button = $UI/EndPanel/QuitButton
@onready var sun = $Sun
@onready var ore_label: Label = $UI/HBoxContainer/VBoxContainer/OreLabel
@onready var carried_ore_label: Label = $UI/HBoxContainer/VBoxContainer/CarriedOreLabel
@onready var spawner_manager = $SpawnerManager
@onready var construction_menu = $UI/ConstructionMenu

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

func _ready():
	if not camera:
		camera = get_node("/root/Level/Camera")
	else:
		camera.set_player(player)
	if player:
		player.ore_carried.connect(_on_ore_carried)
		player.set_process_input(false)  # Disable player input during loading
	else:
		push_error("Player node not found")
	if construction_menu:
		construction_menu.building_placed.connect(_on_building_placed)
		construction_menu.placement_failed.connect(_on_placement_failed)
	else:
		push_error("ConstructionMenu node not found")
	if not end_panel:
		push_error("EndPanel node not found")
	end_panel.visible = false
	restart_button.connect("pressed", _on_restart_pressed)
	quit_button.connect("pressed", _on_quit_pressed)
	var max_waves = 0
	for spawner in spawner_manager.get_children():
		for wave_res in spawner.waves:
			max_waves = max(max_waves, wave_res.wave_counts.size())
	total_waves = max(total_waves, max_waves)
	
	# Connect building destruction signals
	for building in get_tree().get_nodes_in_group("buildings"):
		if building.has_signal("destroyed"):
			building.destroyed.connect(_on_building_destroyed)
			if building.resource and building.resource.building_name == "headquarters":
				building.destroyed.connect(_on_hq_destroyed)
	
	# Initialize enemy pool and wait for completion
	spawner_manager.initialize_pool()
	await spawner_manager.pool_ready
	
	update_ui()

func _process(delta):
	match current_state:
		State.PLACING:
			if sun: sun.light_energy = 0.75
		State.DAY:
			if sun: sun.light_energy = 1.0
			day_timer -= delta
			mission_stats.time_taken += delta
			if day_timer <= 0:
				start_night()
		State.NIGHT:
			if sun: sun.light_energy = 0.25
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

func assign_planet(passed_in_name: String):
	planet_name = passed_in_name

func _on_building_placed(building_name: String, place_position: Vector3):
	if building_name == "headquarters" and not has_hq:
		has_hq = true
		current_state = State.DAY
		day_timer = day_duration
		var hq = get_node_or_null("Buildings/HeadQuarters")
		if hq:
			hq.hq_destroyed.connect(_on_hq_destroyed)
			hq.health_changed.connect(_on_hq_health_changed)
			hq_health_label.text = "HQ Health: %d" % hq.health
			print("HQ placed at %s, connected signals" % place_position)
		else:
			push_warning("HQ node not found at Buildings/HeadQuarters")
		update_ui()

func start_day_func():
	current_state = State.DAY
	day_timer = day_duration
	if spawner_manager:
		spawner_manager.end_night()
	if wave_count >= total_waves:
		end_level(true)
	start_day.emit()

func start_night():
	wave_count += 1
	mission_stats.waves_survived = wave_count
	current_state = State.NIGHT
	night_start_time = Time.get_ticks_msec() / 1000.0
	if spawner_manager:
		spawner_manager.start_night(wave_count)

func end_level(won: bool):
	mission_stats.enemies_killed = spawner_manager.get_total_enemies_killed()
	if won:
		current_state = State.WON
		print("Level Complete! You Win!")
		var end_mission = preload("res://menus/end_mission.tscn").instantiate()
		add_child(end_mission)
		var bonus_points = (mission_stats.enemies_killed * 10) + (int(mission_stats.time_taken / 60) * 100) - (mission_stats.buildings_destroyed * 50)
		end_mission.display_results(mission_stats, true)
		GameState.complete_planet(
			planet_name, 
			won, 
			mission_stats.ore_launched, 
			mission_stats.time_taken, 
			mission_stats.waves_survived, 
			mission_stats.enemies_killed,
			bonus_points
		)
	else:
		current_state = State.LOST
		print("Game Over! HQ Destroyed!")
		end_label.text = "Defeat!"
		get_tree().paused = true
		end_panel.visible = true
		wave_label.text = ""
		enemies_label.text = ""
		GameState.complete_planet(
			planet_name, 
			won, 
			mission_stats.ore_launched, 
			mission_stats.time_taken, 
			mission_stats.waves_survived, 
			mission_stats.enemies_killed,
			0
		)

func _on_placement_failed(building_name: String, reason: String):
	print("Placement failed for %s: %s" % [building_name, reason])
	# TODO: Add UI popup or label to show failure reason to player

func _on_hq_destroyed(_building_name: String):
	print("HQ destroyed, triggering end_level")
	end_level(false)

func _on_hq_health_changed(health):
	hq_health_label.text = "HQ Health: %d" % health

func _on_ore_carried(_amount):
	pass

func _on_ore_deposited(amount):
	player_ore += amount
	mission_stats.ore_launched = player_ore
	update_ui()

func _on_building_destroyed(_building_name: String):
	mission_stats.buildings_destroyed += 1

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://StarMenu/star_menu.tscn")

func update_ui():
	if current_state == State.DAY:
		day_timer_label.text = "Day: %.1f" % day_timer
	elif current_state == State.NIGHT:
		day_timer_label.text = "Night"
	elif current_state == State.WON:
		day_timer_label.text = "Victory!"
	elif current_state == State.LOST:
		day_timer_label.text = "Defeat!"
	elif current_state == State.PLACING:
		day_timer_label.text = "Place HQ"
	wave_label.text = "Wave: %d/%d" % [wave_count, total_waves]
	enemies_label.text = "Enemies: %d" % enemy_count
	ore_label.text = "Stored: %d" % player_ore
	carried_ore_label.text = "Carried: %d" % player.carried_ore
