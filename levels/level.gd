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

var enemy_scene = preload("res://scenes/enemy.tscn")
var ground_size = Vector2(100, 100)

enum State { PLACING, DAY, NIGHT, WON, LOST }
var current_state = State.PLACING
var day_duration = 120.0
var day_timer = 0.0
var wave_count = 0
var total_waves = 2
var player_ore = 0
var planet_name = "alpha_one"
var has_hq = false

func _ready():
	if not camera:
		camera = get_node("/root/Level/Camera")
		if not camera:
			print("Error: Camera not found!")
	else:
		camera.set_player(player)
	player.connect("building_placed", _on_building_placed)
	player.connect("ore_carried", _on_ore_carried)
	player.connect("ore_deposited", _on_ore_deposited)
	end_panel.visible = false
	restart_button.connect("pressed", _on_restart_pressed)
	quit_button.connect("pressed", _on_quit_pressed)
	if sun:
		print("Sun node: ", sun, " Type: ", sun.get_class())
	else:
		print("Sun is null!")
	update_ui()
	print("Level root: ", get_tree().root.get_path(), " Current scene: ", get_tree().current_scene.get_path())

func _process(delta):
	match current_state:
		State.PLACING:
			if sun: sun.light_energy = 0.5
		State.DAY:
			if sun: sun.light_energy = 1.0
			day_timer -= delta
			if day_timer <= 0:
				start_night()
		State.NIGHT:
			if sun: sun.light_energy = 0.3
			var enemy_count = get_tree().get_nodes_in_group("enemies").size()
			if enemy_count == 0 and wave_count > 0:
				start_day()
		State.WON, State.LOST:
			pass
	
	if Input.is_action_just_pressed("winleveldebug"):
		end_level(true)
	
	update_ui()

func assign_planet(passed_in_name: String):
	planet_name = passed_in_name
	print("Assigned planet: ", planet_name)

func _on_building_placed(building_name: String, position: Vector3):
	if building_name == "hq":
		has_hq = true
		current_state = State.DAY
		day_timer = day_duration
		var hq = get_node_or_null("HeadQuarters")
		if hq:
			hq.connect("hq_destroyed", _on_hq_destroyed)
			hq.connect("health_changed", _on_hq_health_changed)
			hq_health_label.text = "HQ Health: %d" % hq.health
	else:
		if not has_hq:
			print("Cannot place ", building_name, " - HQ required!")
			return
		var cost = player.building_configs.get(building_name, {}).get("cost", 0)
		if current_state == State.DAY and player_ore >= cost:
			player_ore -= cost
			update_ui()
		else:
			print("Not enough ore or not daytime for ", building_name)

func start_day():
	current_state = State.DAY
	day_timer = day_duration
	if wave_count >= total_waves:
		end_level(true)
	else:
		print("Day ", wave_count + 1, " started")

func start_night():
	wave_count += 1
	current_state = State.NIGHT
	spawn_wave()

func spawn_wave():
	var enemy_count = 5 + ((wave_count - 1) * 2)
	print("Spawning wave ", wave_count, " with ", enemy_count, " enemies")
	for i in range(enemy_count):
		var enemy = enemy_scene.instantiate()
		var side = randi() % 4
		var pos = Vector3.ZERO
		match side:
			0: pos = Vector3(randf_range(-ground_size.x/2, ground_size.x/2), 0, -ground_size.y/2)
			1: pos = Vector3(ground_size.x/2, 0, randf_range(-ground_size.y/2, ground_size.y/2))
			2: pos = Vector3(randf_range(-ground_size.x/2, ground_size.x/2), 0, ground_size.y/2)
			3: pos = Vector3(-ground_size.x/2, 0, randf_range(-ground_size.y/2, ground_size.y/2))
		enemy.global_position = pos
		add_child(enemy)

func end_level(won: bool):
	if won:
		current_state = State.WON
		print("Level Complete! You Win!")
		end_label.text = "Victory!"
		GameState.complete_planet(planet_name)
	else:
		current_state = State.LOST
		print("Game Over! HQ Destroyed!")
		end_label.text = "Defeat!"
	end_panel.visible = true
	wave_label.text = ""
	enemies_label.text = ""
	get_tree().paused = true
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")

func _on_hq_destroyed():
	end_level(false)

func _on_hq_health_changed(health):
	hq_health_label.text = "HQ Health: %d" % health

func _on_ore_carried(amount):
	pass

func _on_ore_deposited(amount):
	player_ore += amount
	update_ui()

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")

func update_ui():
	if not day_timer_label or not wave_label or not enemies_label or not hq_health_label or not ore_label or not carried_ore_label:
		print("UI Error: One or more labels are null")
		return
	if current_state == State.DAY:
		day_timer_label.text = "Day: %.1f" % day_timer
	elif current_state == State.NIGHT:
		day_timer_label.text = "Night"
	elif current_state == State.WON:
		day_timer_label.text = "Victory!"
	elif current_state == State.LOST:
		day_timer_label.text = "Defeat!"
	wave_label.text = "Wave: %d/%d" % [wave_count, total_waves]
	enemies_label.text = "Enemies: %d" % get_tree().get_nodes_in_group("enemies").size()
	ore_label.text = "Stored: %d" % player_ore
	carried_ore_label.text = "Carried: %d" % player.carried_ore
