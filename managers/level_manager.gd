# res://scripts/level_manager.gd
extends Node

signal start_day
signal start_night

var ground_size = Vector2(100, 100)

enum State { PLACING, DAY, NIGHT, WON, LOST }
var current_state = State.PLACING
var day_duration = 20.0
var day_timer = 0.0
var wave_count = 0
var total_waves = 2
var player_ore = 0
var planet_name = "alpha_one"
var has_hq = false
var night_start_time = 0.0
var mission_stats = {"ore_launched": 0, "time_taken": 0.0, "waves_survived": 0, "enemies_killed": 0, "buildings_destroyed": 0}
var enemy_count = 0
var level_path = ""

@onready var player = get_tree().get_root().get_node_or_null("Level/Player")
@onready var day_timer_label = %DayTimerLabel
@onready var wave_label = %WaveLabel
@onready var enemies_label = %EnemiesLabel
@onready var hq_health_label = %HQHealthLabel
@onready var end_panel = %EndPanel
@onready var end_label = %EndLabel
@onready var restart_button = %RestartButton
@onready var quit_button = %QuitButton
@onready var ore_label = %OreLabel
@onready var carried_ore_label = %CarriedOreLabel

var spawner_manager

func _init() -> void:
	set_process(false)

func _ready():
	set_process(false)
	$UI.visible = false
	if end_panel:
		end_panel.visible = false
	else:
		push_error("EndPanel node not found")
	if restart_button:
		restart_button.connect("pressed", _on_restart_pressed)
	if quit_button:
		quit_button.connect("pressed", _on_quit_pressed)
	else:
		push_error("SpawnerManager not found")
	update_ui()

## func to init global - before level start
func start():
	if player:
		player.ore_carried.connect(_on_ore_carried)
	else:
		push_error("Player node not found")
	set_process(true)
	$UI.visible = true

## func to init global - before level start
func stop():
	set_process(false)
	$UI.visible = false

func _process(delta):
	match current_state:
		State.PLACING:
			pass
		State.DAY:
			day_timer -= delta
			mission_stats.time_taken += delta
			if day_timer <= 0:
				start_night_func()
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

func assign_planet(passed_in_name: String):
	planet_name = passed_in_name

func _on_hq_placed(building_name: String, _place_position: Vector3):
	if building_name == "headquarters" and not has_hq:
		has_hq = true
		current_state = State.DAY
		day_timer = day_duration
		var hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")
		if hq:
			_connect_hq_signals(hq)
			hq_health_label.text = "HQ Health: %d" % hq.health
			print("HQ placed at %s, connected signals" % _place_position)
		else:
			push_warning("HQ node not found at Level/Buildings/HeadQuarters")
		update_ui()

func _connect_hq_signals(hq: Node):
	if hq.has_signal("destroyed"):
		if not hq.destroyed.is_connected(_on_hq_destroyed):
			hq.destroyed.connect(_on_hq_destroyed)
	if hq.has_signal("health_changed"):
		if not hq.health_changed.is_connected(_on_hq_health_changed):
			hq.health_changed.connect(_on_hq_health_changed)
	if hq.has_signal("placed"):
		if not hq.placed.is_connected(_on_hq_placed):
			hq.placed.connect(_on_hq_placed)

func start_day_func():
	current_state = State.DAY
	day_timer = day_duration
	if spawner_manager:
		spawner_manager.end_night()
	if wave_count >= total_waves:
		end_level(true)
	start_day.emit()

func start_night_func():
	wave_count += 1
	mission_stats.waves_survived = wave_count
	current_state = State.NIGHT
	night_start_time = Time.get_ticks_msec() / 1000.0
	if spawner_manager:
		spawner_manager.start_night(wave_count)

func end_level(won: bool):
	mission_stats.enemies_killed = spawner_manager.get_total_enemies_killed() if spawner_manager else 0
	if won:
		current_state = State.WON
		print("Level Complete! You Win!")
		var end_mission = preload("res://menus/end_mission.tscn").instantiate()
		get_tree().root.get_node("Level").add_child(end_mission)
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
		if end_label:
			end_label.text = "Defeat!"
		if end_panel:
			end_panel.visible = true
		get_tree().paused = true
		if wave_label:
			wave_label.text = ""
		if enemies_label:
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
	if hq_health_label:
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
	if $UI.visible == false:
		return
	if not day_timer_label or not wave_label or not enemies_label or not ore_label or not carried_ore_label:
		return
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
