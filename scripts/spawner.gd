extends Node3D

signal enemy_spawned(enemy)

@export var waves: Array[Spawn] = []
@export var spawn_rate: float = 0.2
@export var max_spawn_retries: int = 10  # Limit retries to prevent infinite loops

var current_wave: int = 0
var enemies_to_spawn: Array[Dictionary] = []  # [{enemy: PackedScene, count: int}, ...]
var is_active: bool = false

@onready var area = $Area3D
@onready var timer = $Timer

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

func _ready():
	mesh_instance_3d.queue_free()
	timer.wait_time = spawn_rate
	timer.connect("timeout", _on_timer_timeout)
	validate_waves()

func validate_waves():
	for wave in waves:
		if not wave is Spawn:
			waves.erase(wave)
		elif not wave.enemy_scene:
			waves.erase(wave)
		elif not wave.wave_counts is Array:
			wave.wave_counts = []
		for i in range(wave.wave_counts.size()):
			if not wave.wave_counts[i] is int:
				wave.wave_counts[i] = 0
			elif wave.wave_counts[i] < 0:
				wave.wave_counts[i] = 0

func get_max_wave_counts() -> Dictionary:
	var max_counts = {}  # Key: String (resource path), Value: int
	for wave_res in waves:
		var scene = wave_res.enemy_scene
		if scene:
			var scene_path = scene.resource_path
			var max_count = 0
			for count in wave_res.wave_counts:
				max_count = max(max_count, count)
			max_counts[scene_path] = max_counts.get(scene_path, 0) + max_count
		else:
			print("Warning: Invalid enemy_scene in wave resource")
	return max_counts

func get_enemy_scene(scene_path: String) -> PackedScene:
	for wave_res in waves:
		if wave_res.enemy_scene and wave_res.enemy_scene.resource_path == scene_path:
			return wave_res.enemy_scene
	return null

func activate_for_wave(wave: int):
	current_wave = wave
	enemies_to_spawn.clear()
	if wave == 0:
		is_active = false
		timer.stop()
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
	else:
		is_active = false
		timer.stop()

func _on_timer_timeout():
	if is_active and enemies_to_spawn.size() > 0:
		spawn_enemy_with_retries()

func spawn_enemy_with_retries():
	var retries = 0
	while retries < max_spawn_retries:
		var spawn_position = get_random_position_in_area()
		if try_spawn_at_position(spawn_position):
			return  # Success
		retries += 1

func get_random_position_in_area() -> Vector3:
	if not area or not area.get_node("CollisionShape3D"):
		return global_position
	var collision_shape = area.get_node("CollisionShape3D")
	var shape = collision_shape.shape
	var pos = global_position
	if shape is BoxShape3D:
		var extents = shape.extents
		pos += Vector3(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y),
			randf_range(-extents.z, extents.z)
		)
	elif shape is SphereShape3D:
		var radius = shape.radius
		var random_vec = Vector3(randf_range(-radius, radius), randf_range(-radius, radius), randf_range(-radius, radius))
		if random_vec.length() <= radius:
			pos += random_vec
		else:
			pos += random_vec.normalized() * randf_range(0.0, radius)
	elif shape is CylinderShape3D:
		var radius = shape.radius
		var height = shape.height
		var angle = randf_range(0.0, 2.0 * PI)
		var r = radius * sqrt(randf_range(0.0, 1.0))
		var x = r * cos(angle)
		var z = r * sin(angle)
		var y = randf_range(-height / 2.0, height / 2.0)
		pos += Vector3(x, y, z)
	return pos

func try_spawn_at_position(pos: Vector3) -> bool:
	if not area:
		return false
	var space_state = get_world_3d().direct_space_state
	var shape = CylinderShape3D.new()
	shape.radius = 1.0
	shape.height = 1.0
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), pos + Vector3(0, 0.5, 0))
	query.collision_mask = 2
	
	var result = space_state.intersect_shape(query)
	if result.size() > 0:
		return false
	
	var entry = enemies_to_spawn[0]
	var enemy = get_parent().request_enemy(entry["enemy"])
	if enemy:
		enemy.reset(pos)
		emit_signal("enemy_spawned", enemy)
		entry["count"] -= 1
		if entry["count"] <= 0:
			enemies_to_spawn.remove_at(0)
		if enemies_to_spawn.size() == 0:
			timer.stop()
			is_active = false
		return true
	return false
