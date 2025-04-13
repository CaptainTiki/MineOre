extends Node3D

signal enemy_spawned(enemy)

@export var waves: Array[Spawn] = []
@export var spawn_rate: float = 2.0

var current_wave: int = 0
var enemies_to_spawn: Array[Dictionary] = []  # [{enemy: PackedScene, count: int}, ...]
var is_active: bool = false

@onready var area = $Area3D
@onready var timer = $Timer

func _ready():
	timer.wait_time = spawn_rate
	timer.connect("timeout", _on_timer_timeout)
	if not area:
		print("Error: No Area3D for ", name)
	validate_waves()
	print("Spawner ", name, " ready with waves: ", waves)

func validate_waves():
	for wave in waves:
		if not wave is Spawn:
			print("Error: Invalid Spawn resource in ", name)
			waves.erase(wave)
		elif not wave.enemy_scene:
			print("Error: No enemy_scene in Spawn for ", name)
			waves.erase(wave)
		elif not wave.wave_counts is Array:
			print("Error: Invalid wave_counts in Spawn for ", name)
			wave.wave_counts = []
		for i in range(wave.wave_counts.size()):
			if not wave.wave_counts[i] is int:
				print("Error: Invalid count at index ", i, " in Spawn for ", name)
				wave.wave_counts[i] = 0
			elif wave.wave_counts[i] < 0:
				print("Error: Negative count at index ", i, " in Spawn for ", name)
				wave.wave_counts[i] = 0

func activate_for_wave(wave: int):
	current_wave = wave
	enemies_to_spawn.clear()
	if wave == 0:
		is_active = false
		timer.stop()
		print("Spawner ", name, " deactivated")
		return
	var wave_index = wave - 1
	for wave_res in waves:
		if wave_index < wave_res.wave_counts.size():
			var count = wave_res.wave_counts[wave_index]
			if count > 0:
				enemies_to_spawn.append({"enemy": wave_res.enemy_scene, "count": count})
	if enemies_to_spawn.size() > 0:
		is_active = true
		timer.start()
		print("Spawner ", name, " activated for wave ", wave, " with ", enemies_to_spawn)
	else:
		is_active = false
		timer.stop()
		print("Spawner ", name, " inactive for wave ", wave, ": no enemies")

func _on_timer_timeout():
	if is_active and enemies_to_spawn.size() > 0:
		if is_area_clear():
			spawn_enemy()
		else:
			print("Spawner ", name, " blocked: area not clear, enemies pending: ", enemies_to_spawn)

func is_area_clear() -> bool:
	if not area:
		print("Error: Area3D missing for ", name)
		return false
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			print("Spawner ", name, " blocked by enemy: ", body.name)
			return false
	return true

func spawn_enemy():
	if enemies_to_spawn.size() == 0:
		timer.stop()
		is_active = false
		print("Spawner ", name, " depleted for wave ", current_wave)
		return
	var entry = enemies_to_spawn[0]
	var enemy_scene = entry["enemy"]
	if not enemy_scene:
		print("Error: No enemy_scene for ", name)
		enemies_to_spawn.remove_at(0)
		return
	var enemy = enemy_scene.instantiate()
	enemy.global_position = global_position
	get_tree().get_root().get_node("Level").add_child(enemy)
	emit_signal("enemy_spawned", enemy)
	entry["count"] -= 1
	print("Spawned ", enemy.name, " at ", name, ", counts left: ", enemies_to_spawn)
	if entry["count"] <= 0:
		enemies_to_spawn.remove_at(0)
	if enemies_to_spawn.size() == 0:
		timer.stop()
		is_active = false
		print("Spawner ", name, " depleted for wave ", current_wave)
