extends Node

signal wave_started(wave)
signal pool_ready

var total_enemies_killed: int = 0
var current_wave: int = 0
var is_night: bool = false
var enemy_pool: Dictionary = {
	"scrapper": [],
	"striker": []
	# Add "worm" later
}
var max_pool_size_per_type: Dictionary = {
	"scrapper": 0,
	"striker": 0
}
var enemy_scenes: Dictionary = {}  # Maps type to PackedScene

func _ready():
	print("SpawnerManager ready, awaiting night signal")

func initialize_pool():
	# Calculate max enemies needed per type across all spawners
	for spawner in get_children():
		if spawner.has_method("get_max_wave_counts"):
			var max_counts = spawner.get_max_wave_counts()
			for type in max_counts:
				max_pool_size_per_type[type] += max_counts[type]
	
	# Add 20% buffer and instantiate enemies
	for type in max_pool_size_per_type:
		var count = ceil(max_pool_size_per_type[type] * 1.2)
		var scene = get_spawner_enemy_scene(type)
		if scene:
			enemy_scenes[type] = scene
			for i in range(count):
				var enemy = scene.instantiate()
				enemy.global_position = Vector3(999, 999, 999)
				enemy.visible = false
				enemy.set_physics_process(false)
				get_tree().get_root().get_node("Level").add_child(enemy)
				enemy_pool[type].append(enemy)
				enemy.connect("died", Callable(self, "_on_enemy_died").bind(enemy, type))
	
	print("Enemy pool initialized: ", max_pool_size_per_type)
	await get_tree().create_timer(0.1).timeout  # Brief delay to spread load
	emit_signal("pool_ready")

func get_spawner_enemy_scene(type: String) -> PackedScene:
	# Find a spawner with the enemy scene for the type
	for spawner in get_children():
		if spawner.has_method("get_enemy_scene"):
			var scene = spawner.get_enemy_scene(type)
			if scene:
				return scene
	return null

func request_enemy(enemy_scene: PackedScene) -> Node:
	var type = "scrapper" if enemy_scene == enemy_scenes.get("scrapper") else "striker"
	if enemy_pool[type].size() > 0:
		return enemy_pool[type].pop_back()
	# Fallback: instantiate new enemy (with cap)
	if max_pool_size_per_type[type] < 50:  # Hard cap to avoid runaway memory
		var enemy = enemy_scenes[type].instantiate()
		enemy.global_position = Vector3(999, 999, 999)
		enemy.visible = false
		enemy.set_physics_process(false)
		get_tree().get_root().get_node("Level").add_child(enemy)
		enemy.connect("died", Callable(self, "_on_enemy_died").bind(enemy, type))
		max_pool_size_per_type[type] += 1
		return enemy
	print("Warning: No ", type, " enemies available in pool")
	return null

func _on_enemy_died(enemy: Node, type: String):
	enemy.global_position = Vector3(999, 999, 999)
	enemy.visible = false
	enemy.is_alive = false
	enemy.set_physics_process(false)
	enemy_pool[type].append(enemy)
	total_enemies_killed += 1

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
