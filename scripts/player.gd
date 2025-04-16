# res://scripts/player.gd
extends CharacterBody3D

signal ore_carried(amount)
signal ore_deposited(amount)
signal building_placed(building_name, position)
signal placement_failed(building_name, reason)

enum Tool { NONE, GUN, MINING_LASER }
var current_tool = Tool.NONE
var speed = 5.0
var bullet_scene = preload("res://scenes/bullet.tscn")
var carry_capacity = 20
var carried_ore = 0
var is_placing = false
var preview_instance = null
var preview_scene_path = ""
var preview_building_name = ""
var preview_distance = 4.0
var grid_size = 2.0  # Each cell is 2x2 units
var preview_material = null  # Store the preview material

@onready var camera = get_node_or_null("../Camera")
@onready var construction_menu = get_tree().get_root().get_node_or_null("Level/UI/ConstructionMenu")
@onready var placement_grid = preload("res://scenes/placement_grid.tscn").instantiate()

func _ready():
	Input.action_release("action")
	add_to_group("player")
	$Gun.visible = false
	$MiningLaser.visible = false
	$MiningLaser/Cone.monitoring = false
	if not camera:
		camera = get_tree().root.get_node_or_null("Level/Camera")
	get_tree().root.get_node("Level").add_child(placement_grid)
	placement_grid.hide_grid()
	print("Player initialized, PlacementGrid added to scene")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("build"):
		if construction_menu.visible:
			construction_menu.hide_menu()
			cancel_placement()
		else:
			construction_menu.show_menu()
			cancel_placement()

	if is_placing and preview_instance:
		update_preview_position()
		if Input.is_action_just_pressed("action"):
			place_building()
		if Input.is_action_just_pressed("cancel"):
			cancel_placement()

	if not is_placing:
		if Input.is_action_just_pressed("action") and not construction_menu.visible:
			match current_tool:
				Tool.GUN:
					shoot_bullet()
				Tool.MINING_LASER:
					mine_ore()
		if Input.is_action_just_pressed("interact"):
			interact_with_building()

func _physics_process(delta):
	var input = Vector3.ZERO
	if Input.is_action_pressed("move_forward"): input.z -= 1
	if Input.is_action_pressed("move_backward"): input.z += 1
	if Input.is_action_pressed("move_left"): input.x -= 1
	if Input.is_action_pressed("move_right"): input.x += 1
	
	velocity = input.normalized() * speed
	move_and_slide()
	
	position.x = clamp(position.x, -50, 50)
	position.z = clamp(position.z, -50, 50)
	
	if camera:
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_dir = camera.project_ray_normal(mouse_pos)
		var plane = Plane(Vector3.UP, 0)
		var intersect = plane.intersects_ray(ray_origin, ray_dir)
		if intersect:
			var look_pos = intersect
			look_at(Vector3(look_pos.x, global_position.y, look_pos.z), Vector3.UP)

func _input(event):
	if not is_placing:
		if event.is_action_pressed("tool_gun"):
			switch_tool(Tool.GUN)
		elif event.is_action_pressed("tool_mining_laser"):
			switch_tool(Tool.MINING_LASER)
	if event.is_action_pressed("cancel"):
		cancel_placement()

func switch_tool(new_tool):
	current_tool = new_tool
	$Gun.visible = (current_tool == Tool.GUN)
	$MiningLaser.visible = (current_tool == Tool.MINING_LASER)
	$MiningLaser/Cone.monitoring = (current_tool == Tool.MINING_LASER)

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	var level = get_tree().root.get_node_or_null("Level")
	level.add_child(bullet)
	bullet.global_position = $Gun.global_position
	var bullet_speed = 20.0
	var forward_dir = -transform.basis.z.normalized()
	bullet.velocity = forward_dir * bullet_speed

func mine_ore():
	var bodies = $MiningLaser/Cone.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("ores") and carried_ore < carry_capacity:
			body.queue_free()
			carried_ore += 1
			emit_signal("ore_carried", 1)

func interact_with_building():
	var bodies = $InteractArea.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("collect_ore") and carried_ore < carry_capacity:
			var collected = body.collect_ore(carry_capacity - carried_ore)
			if collected > 0:
				carried_ore += collected
				emit_signal("ore_carried", collected)
		elif body.has_method("deposit_ore") and carried_ore > 0:
			var deposited = body.deposit_ore(carried_ore)
			carried_ore -= deposited
			emit_signal("ore_deposited", deposited)
			var level = get_tree().root.get_node("Level")
			level.player_ore = body.stored_ore
		elif body.has_method("start_launch"):
			body.start_launch()

func start_placement(scene_path: String, building_name: String):
	if is_placing:
		cancel_placement()
	preview_scene_path = scene_path
	preview_building_name = building_name
	preview_instance = load(scene_path).instantiate()
	preview_instance.set_meta("is_preview", true)
	
	var mesh = preview_instance.get_node("MeshInstance3D")
	if mesh:
		preview_material = StandardMaterial3D.new()
		preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		preview_material.albedo_color = Color(0, 1, 0, 0.65)  # Default to green
		mesh.material_override = preview_material
	
	var base_distance = 4.0
	var shape_size_z = 0.0
	var collision_shape = preview_instance.get_node_or_null("CollisionShape3D")
	if collision_shape and collision_shape.shape is BoxShape3D:
		shape_size_z = collision_shape.shape.extents.z
		preview_distance = base_distance + (shape_size_z / 2.0)
	else:
		preview_distance = base_distance
	
	var level = get_tree().root.get_node("Level")
	level.add_child(preview_instance)
	
	# Initialize grid at zero, update position will set it
	var resource = BuildingsManager.get_building_resource(building_name)
	var grid_extents = preview_instance.grid_extents if preview_instance else Vector2i(4, 4)  # Fallback
	placement_grid.start(Vector3.ZERO, building_name, grid_extents)
	placement_grid.show_grid()
	is_placing = true
	print("Placement started for ", building_name, " with grid extents ", grid_extents)
	
	update_preview_position()

func update_preview_position():
	if preview_instance:
		var preview_pos = global_position + (-transform.basis.z.normalized() * preview_distance)
		preview_pos.x = round(preview_pos.x / grid_size) * grid_size
		preview_pos.z = round(preview_pos.z / grid_size) * grid_size
		preview_pos.y = 0
		preview_instance.global_position = preview_pos
		placement_grid.update_position(preview_pos)
		
		# Update preview color based on placement validity
		if preview_material:
			if check_placement_validity():
				preview_material.albedo_color = Color(0, 1, 0, 0.65)  # Green for valid
			else:
				preview_material.albedo_color = Color(1, 0, 0, 0.65)  # Red for invalid

func check_collision(pos: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsPointQueryParameters3D.new()
	query.position = pos
	query.collision_mask = 0b1000100  # Environment and buildings
	var result = space_state.intersect_point(query)
	return result.size() == 0

func check_placement_validity() -> bool:
	if not preview_instance or not preview_scene_path:
		print("Invalid placement: No preview instance or scene path")
		return false
	
	var level = get_tree().root.get_node("Level")
	var is_hq = preview_building_name == "headquarters"
	var hq = level.get_node_or_null("Buildings/HeadQuarters")
	var cost = BuildingsManager.building_configs.get(preview_building_name, {}).get("cost", 0)
	var has_ore = is_hq  # HQ always free
	if not is_hq and hq:
		has_ore = hq.stored_ore >= cost
	
	var space_state = get_world_3d().direct_space_state
	var shape = preview_instance.get_node_or_null("CollisionShape3D")
	if shape and shape.shape:
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = shape.shape
		query.transform = preview_instance.global_transform
		query.collision_mask = 0b1000100  # Environment and buildings
		query.exclude = [self]
		var result = space_state.intersect_shape(query)
		var is_collision_free = result.size() == 0
		if not is_collision_free:
			print("Collision with: ", result)
		return has_ore and is_collision_free
	
	print("No collision shape for ", preview_building_name)
	return false

func place_building():
	if preview_instance and preview_scene_path:
		var cost = BuildingsManager.building_configs.get(preview_building_name, {}).get("cost", 0)
		var level = get_tree().root.get_node("Level")
		var hq = level.get_node_or_null("Buildings/HeadQuarters")
		if check_placement_validity():
			var withdrawn = 0
			if preview_building_name != "headquarters" and cost > 0:
				withdrawn = hq.withdraw_ore(cost)
			if withdrawn == cost or preview_building_name == "headquarters":
				var building = load(preview_scene_path).instantiate()
				building.global_position = preview_instance.global_position
				building.resource = BuildingsManager.get_building_resource(preview_building_name)
				var mesh = building.get_node("MeshInstance3D")
				if mesh:
					mesh.material_override = null
				var buildings_node = level.get_node_or_null("Buildings")
				if not buildings_node:
					buildings_node = Node3D.new()
					buildings_node.name = "Buildings"
					level.add_child(buildings_node)
					buildings_node.owner = level
				buildings_node.add_child(building)
				building.owner = level
				if hq:
					level.player_ore = hq.stored_ore
				emit_signal("building_placed", preview_building_name, building.global_position)
				if preview_building_name == "silo" and hq:
					hq.add_silo()
				if BuildingsManager.building_configs.get(preview_building_name, {}).get("unique", false):
					construction_menu.mark_unique_placed(preview_building_name)
			else:
				emit_signal("placement_failed", preview_building_name, "Not enough ore")
		else:
			emit_signal("placement_failed", preview_building_name, "Invalid position")
		placement_grid.hide_grid()
		cancel_placement()
	else:
		emit_signal("placement_failed", preview_building_name, "Invalid placement")
		placement_grid.hide_grid()
		cancel_placement()

func cancel_placement():
	if preview_instance:
		preview_instance.queue_free()
	placement_grid.hide_grid()
	is_placing = false
	preview_scene_path = ""
	preview_building_name = ""
	preview_distance = 4.0
	preview_material = null  # Clear material reference
	print("Placement cancelled")

func set_player(player_node):
	pass
