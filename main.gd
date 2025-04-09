extends Node3D

@onready var player = $Player
@onready var camera = $Camera
var enemy_scene = preload("res://scenes/enemy.tscn")
var ore_scene = preload("res://scenes/ore.tscn")
var ground_size = Vector2(100, 100)
# Enemy spawn variables
var initial_spawn_delay = 3.0
var min_spawn_delay = 0.33
var ramp_duration = 60.0
var time_elapsed = 0.0
var spawn_timer = 0.0
# Ore spawn variables
var ore_spawn_rate = 5.0  # Seconds between ore spawns
var max_ores = 20  # Max ores on map at once
var ore_timer = 0.0

var base_hp = 100

func _ready():
	camera.set_player(player)
	spawn_ore()
	spawn_ore()
	spawn_ore()

func _process(delta):
	time_elapsed += delta
	spawn_timer += delta
	ore_timer += delta
	
	# Enemy spawning
	var t = clamp(time_elapsed / ramp_duration, 0.0, 1.0)
	var current_spawn_delay = lerp(initial_spawn_delay, min_spawn_delay, t)
	if spawn_timer >= current_spawn_delay:
		spawn_enemy()
		spawn_timer = 0.0
	
	# Ore spawning
	var ore_count = get_tree().get_nodes_in_group("ores").size()
	if ore_timer >= ore_spawn_rate and ore_count < max_ores:
		spawn_ore()
		ore_timer = 0.0

func spawn_enemy():
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

func spawn_ore():
	var ore = ore_scene.instantiate()
	var pos = Vector3(
		randf_range(-ground_size.x/2, ground_size.x/2),
		0.2,
		randf_range(-ground_size.y/2, ground_size.y/2)
	)
	ore.global_position = pos
	add_child(ore)
