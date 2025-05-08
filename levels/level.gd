# res://scripts/level.gd
extends Node3D

@onready var camera = $Camera
@onready var sun = $Sun
@onready var spawner_manager: Node3D = $SpawnerManager

func _ready():
	if not camera:
		camera = get_node("/root/Level/Camera")
	else:
		camera.set_player(get_tree().get_root().get_node_or_null("Level/Player"))
		
	var max_waves = 0
	for spawner in spawner_manager.get_children():
		for wave_res in spawner.waves:
			max_waves = max(max_waves, wave_res.wave_counts.size())
	LevelManager.total_waves = max_waves
	LevelManager.start_day.connect(_on_start_day)
	LevelManager.start_night.connect(_on_start_night)
	LevelManager.player = $Player
	LevelManager.spawner_manager = $SpawnerManager
	spawner_manager.initialize_pool()
	LevelManager.start()

	await $SpawnerManager.pool_ready

func _process(delta):
	match LevelManager.current_state:
		LevelManager.State.PLACING:
			if sun: sun.light_energy = 0.75
		LevelManager.State.DAY:
			if sun: sun.light_energy = 1.0
		LevelManager.State.NIGHT:
			if sun: sun.light_energy = 0.25
		LevelManager.State.WON, LevelManager.State.LOST:
			pass

func _on_start_day():
	# Add level-specific day start effects (e.g., animations, triggers)
	pass

func _on_start_night():
	# Add level-specific night start effects (e.g., enemy ambush, fog)
	pass
