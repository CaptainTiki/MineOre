extends Node

signal wave_started(wave)
signal pool_ready

var total_enemies_killed: int = 0
var current_wave: int = 0
var is_night: bool = false
var enemy_pool: Dictionary = {}  # Key: String (resource path), Value: Array[Node] (enemies)
var max_pool_size_per_scene: Dictionary = {}  # Key: String (resource path), Value: int
var enemy_scenes: Dictionary = {}  # Key: String (resource path), Value: PackedScene

func _ready():
	print("SpawnerManager ready, awaiting night signal")

func initialize_pool():
	# Clear existing pool and sizes
	enemy_pool.clear()
	max_pool_size_per_scene.clear()
	enemy_scenes.clear()

	# Calculate max enemies needed per scene across all spawners
	for spawner in get_children():
		if spawner.has_method("get_max_wave_counts"):
			var max_counts = spawner.get_max_wave_counts()
			for scene_path in max_counts:
				if scene_path and not enemy_scenes.has(scene_path):
					var scene = load(scene_path) as PackedScene
					if scene:
						enemy_scenes[scene_path] = scene
					else:
						print("Warning: Failed to load scene at ", scene_path)
				max_pool_size_per_scene[scene_path] = max_pool_size_per_scene.get(scene_path, 0) + max_counts[scene_path]

	# Initialize pool with 20% buffer for each scene
	for scene_path in enemy_scenes:
		print("createing enemy")
		var count = ceil(max_pool_size_per_scene[scene_path] * 1.2)
		enemy_pool[scene_path] = []
		var scene = enemy_scenes[scene_path]
		if scene:
			for i in range(count):
				var enemy = scene.instantiate()
				get_tree().get_root().get_node("Level/Enemies").add_child(enemy)
				enemy.global_position = Vector3(999, 999, 999)
				enemy.visible = false
				enemy.set_physics_process(false)
				enemy_pool[scene_path].append(enemy)
				enemy.connect("died", Callable(self, "_on_enemy_died").bind(enemy, scene_path))
			print("Initialized pool for scene ", scene_path, ": ", count, " enemies")
		else:
			print("Warning: Skipping pool init for invalid scene ", scene_path)

	await get_tree().create_timer(0.1).timeout  # Brief delay to spread load
	emit_signal("pool_ready")

func get_spawner_enemy_scene(scene_path: String) -> PackedScene:
	# Return the scene if it exists in any spawner's waves
	for spawner in get_children():
		if spawner.has_method("get_enemy_scene"):
			var found_scene = spawner.get_enemy_scene(scene_path)
			if found_scene:
				return found_scene
	return null

func request_enemy(enemy_scene: PackedScene) -> Node:
	var scene_path = enemy_scene.resource_path if enemy_scene else ""
	if not scene_path or not enemy_pool.has(scene_path):
		print("Warning: Invalid or missing scene path ", scene_path)
		return null

	# Check if the scene is in the pool
	if enemy_pool[scene_path].size() > 0:
		return enemy_pool[scene_path].pop_back()
	
	# Fallback: instantiate new enemy (with cap)
	if max_pool_size_per_scene.get(scene_path, 0) < 50:  # Hard cap to avoid runaway memory
		var enemy = enemy_scene.instantiate()
		get_tree().get_root().get_node("Level/Enemies").add_child(enemy)
		enemy.global_position = Vector3(999, 999, 999)
		enemy.visible = false
		enemy.set_physics_process(false)
		enemy.connect("died", Callable(self, "_on_enemy_died").bind(enemy, scene_path))
		max_pool_size_per_scene[scene_path] = max_pool_size_per_scene.get(scene_path, 0) + 1
		print("Instantiated new enemy for ", scene_path, ", new pool size: ", max_pool_size_per_scene[scene_path])
		return enemy
	
	print("Warning: No enemies available for scene ", scene_path)
	return null

func _on_enemy_died(enemy: Node, scene_path: String):
	enemy.global_position = Vector3(999, 999, 999)
	enemy.visible = false
	enemy.is_alive = false
	enemy.set_physics_process(false)
	if enemy_pool.has(scene_path):
		enemy_pool[scene_path].append(enemy)
		total_enemies_killed += 1
	else:
		print("Error: Scene path ", scene_path, " not found in enemy_pool. Cannot return enemy to pool.")

func start_night(wave: int):
	if not is_night:
		is_night = true
		current_wave = wave
		emit_signal("wave_started", wave)
		var active_spawners = 0
		for spawner in get_children():
			if spawner.has_method("activate_for_wave"):
				spawner.activate_for_wave(wave)
				if spawner.get("is_active") == true:
					active_spawners += 1
		print("Night started, wave ", wave, ", active spawners: ", active_spawners)
		if active_spawners == 0:
			print("Warning: No spawners activated for wave ", wave)

func end_night():
	is_night = false
	for spawner in get_children():
		if spawner.has_method("activate_for_wave"):
			spawner.activate_for_wave(0)  # Deactivate
	print("Night ended")

func has_active_spawners() -> bool:
	for spawner in get_children():
		if spawner.get("is_active") == true:
			return true
	return false

func get_total_enemies_killed() -> int:
	return total_enemies_killed
