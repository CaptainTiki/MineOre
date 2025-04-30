# res://scripts/level.gd
extends Node3D

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
var day_duration = 60.0
var day_timer = 0.0
var wave_count = 0
var total_waves = 2
var player_ore = 0
var planet_name = "alpha_one"
var has_hq = false
var night_start_time = 0.0
var mission_stats = {"ore_launched": 0, "time_taken": 0.0, "waves_survived": 0, "enemies_killed": 0}

func _ready():
	if not camera:
		camera = get_node("/root/Level/Camera")
	else:
		camera.set_player(player)
	if player:
		player.building_placed.connect(_on_building_placed)
		player.ore_carried.connect(_on_ore_carried)
		player.placement_failed.connect(_on_placement_failed)
	else:
		push_error("Player node not found")
	end_panel.visible = false
	restart_button.connect("pressed", _on_restart_pressed)
	quit_button.connect("pressed", _on_quit_pressed)
	var max_waves = 0
	for spawner in spawner_manager.get_children():
		for wave_res in spawner.waves:
			max_waves = max(max_waves, wave_res.wave_counts.size())
	total_waves = max(total_waves, max_waves)
	
	update_ui()

func _process(delta):
	match current_state:
		State.PLACING:
			if sun: sun.light_energy = 0.5
		State.DAY:
			if sun: sun.light_energy = 1.0
			day_timer -= delta
			mission_stats.time_taken += delta
			if day_timer <= 0:
				start_night()
		State.NIGHT:
			if sun: sun.light_energy = 0.3
			var time_since_night = Time.get_ticks_msec() / 1000.0 - night_start_time
			var enemy_count = get_tree().get_nodes_in_group("enemies").size()
			if time_since_night > 1.0:
				if enemy_count == 0 and wave_count > 0 and not spawner_manager.has_active_spawners():
					start_day()
		State.WON, State.LOST:
			pass
	
	if Input.is_action_just_pressed("leveldebug"):
		mission_stats.ore_launched = 30
		mission_stats.waves_survived = 2
		mission_stats.enemies_killed = 10
		end_level(true)
	
	update_ui()

func assign_planet(passed_in_name: String):
	planet_name = passed_in_name

func _on_building_placed(building_name: String, _place_position: Vector3):
	if building_name == "headquarters":
		has_hq = true
		current_state = State.DAY
		day_timer = day_duration
		var hq = get_node_or_null("Buildings/HeadQuarters")
		if hq:
			hq.hq_destroyed.connect(_on_hq_destroyed)
			hq.health_changed.connect(_on_hq_health_changed)
			hq_health_label.text = "HQ Health: %d" % hq.health
			print("HQ placed, starting day/night cycle")
	else:
		if not has_hq:
			return
		update_ui()

func start_day():
	current_state = State.DAY
	day_timer = day_duration
	if spawner_manager:
		spawner_manager.end_night()
	if wave_count >= total_waves:
		end_level(true)
	print("Starting day, timer: %.1f" % day_timer)

func start_night():
	wave_count += 1
	mission_stats.waves_survived = wave_count
	current_state = State.NIGHT
	night_start_time = Time.get_ticks_msec() / 1000.0
	if spawner_manager:
		spawner_manager.start_night(wave_count)
	print("Starting night, wave: %d" % wave_count)

func end_level(won: bool):
	if won:
		current_state = State.WON
		print("Level Complete! You Win!")
		end_label.text = "Victory!"
		$UI/EndPanel/RestartButton.visible = false
		$UI/EndPanel/QuitButton.visible = false
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
		mission_stats.enemies_killed
	)
	print("Changing to starmap")
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://StarMenu/star_menu.tscn")

func _on_placement_failed(building_name: String, reason: String):
	print("Placement failed for %s: %s" % [building_name, reason])
	# TODO: Add UI popup or label to show failure reason to player

func _on_hq_destroyed():
	end_level(false)

func _on_hq_health_changed(health):
	hq_health_label.text = "HQ Health: %d" % health

func _on_ore_carried(_amount):
	pass

func _on_ore_deposited(amount):
	player_ore += amount
	mission_stats.ore_launched = player_ore
	update_ui()

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
	enemies_label.text = "Enemies: %d" % get_tree().get_nodes_in_group("enemies").size()
	ore_label.text = "Stored: %d" % player_ore
	carried_ore_label.text = "Carried: %d" % player.carried_ore
