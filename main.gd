extends Node3D

var ore_count = 0
var base_hp = 100
var ore_scene = preload("res://scenes/ore.tscn")
var enemy_scene = preload("res://scenes/enemy.tscn")
var refinery_scene = preload("res://scenes/refinery.tscn")
var turret_scene = preload("res://scenes/turret.tscn")

func _ready():
	$UI/VBoxContainer/RefineryButton.pressed.connect(_on_refinery_button_pressed)
	$UI/VBoxContainer/TurretButton.pressed.connect(_on_turret_button_pressed)
	spawn_ores(5)
	$Player.connect("mined_ore", _on_player_mined_ore)
	# Defer the set_player call until the Camera is fully ready
	$Camera.set_player($Player)
	#call_deferred("_setup_camera")

func _setup_camera():
	$Camera.set_player($Player)

func _process(delta):
	$UI/VBoxContainer/OreLabel.text = "Ore: %d" % ore_count
	$UI/VBoxContainer/BaseHPLabel.text = "Base HP: %d" % base_hp
	if base_hp <= 0:
		get_tree().quit() # Simple game over for now

	if randf() < 0.005: # Spawn enemies occasionally
		spawn_enemy()

func spawn_ores(n):
	for i in n:
		var ore = ore_scene.instantiate()
		ore.position = Vector3(randf_range(-9, 9), 0.25, randf_range(-9, 9))
		$Ores.add_child(ore)

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	var edge = randi() % 4
	var pos = Vector3.ZERO
	if edge == 0: pos = Vector3(-10, 0.5, randf_range(-9, 9)) # Left
	elif edge == 1: pos = Vector3(10, 0.5, randf_range(-9, 9)) # Right
	elif edge == 2: pos = Vector3(randf_range(-9, 9), 0.5, -10) # Top
	else: pos = Vector3(randf_range(-9, 9), 0.5, 10) # Bottom
	enemy.position = pos
	$Enemies.add_child(enemy)

func _on_player_mined_ore():
	ore_count += 10
	spawn_ores(1)

func _on_refinery_button_pressed():
	if ore_count >= 50:
		ore_count -= 50
		var refinery = refinery_scene.instantiate()
		refinery.position = $Player.position
		$Buildings.add_child(refinery)

func _on_turret_button_pressed():
	if ore_count >= 30:
		ore_count -= 30
		var turret = turret_scene.instantiate()
		turret.position = $Player.position
		$Buildings.add_child(turret)
