# res://scripts/placement_grid.gd
extends Node3D

@onready var grid_mesh = $GridMesh
var grid_size: float = 2.0
var validity: PackedFloat32Array = []

func start(position: Vector3, building_name: String, grid_extents: Vector2i):
	global_position = position
	global_position.y = 0.01
	_process_collision(grid_extents)
	show_grid()
	print("Grid started for ", building_name, " at ", global_position, " with extents ", grid_extents)

func update_position(position: Vector3):
	global_position = position
	global_position.y = 0.01
	_process_collision(Vector2i(8, 8))  # Use full 8x8 grid for now
	print("Grid moved to: ", global_position)

func show_grid():
	visible = true
	print("Grid shown")

func hide_grid():
	visible = false
	print("Grid hidden")

func _process_collision(grid_extents: Vector2i):
	validity.clear()
	var space_state = get_world_3d().direct_space_state
	# Use full 8x8 grid to match 16x16 plane
	for x in range(-4, 4):
		for z in range(-4, 4):
			var check_pos = global_position + Vector3(x * grid_size, 0.01, z * grid_size)
			var query = PhysicsPointQueryParameters3D.new()
			query.position = check_pos
			query.collision_mask = 0b1000100  # Layers 3 and 7
			var result = space_state.intersect_point(query)
			validity.append(1.0 if result.size() == 0 else 0.0)
	print("Collision check complete. Invalid squares: ", validity.count(0.0))
