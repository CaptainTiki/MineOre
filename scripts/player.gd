extends CharacterBody3D

signal ore_carried(amount)
signal ore_deposited(amount)
signal building_placed(building_name, position)

enum Tool { NONE, GUN, MINING_LASER }
var current_tool = Tool.NONE
var speed = 5.0
var bullet_scene = preload("res://scenes/bullet.tscn") # Check if bullet.tscn moved
var carry_capacity = 20
var carried_ore = 0
var is_placing = false
var preview_instance = null
var preview_scene_path = ""
var preview_building_name = ""
var preview_distance = 4.0

@onready var camera = get_node_or_null("../Camera")
@onready var construction_menu = get_tree().get_root().get_node_or_null("Level/UI/ConstructionMenu")

func _ready():
	Input.action_release("action")
	add_to_group("player")
	$Gun.visible = false
	$MiningLaser.visible = false
	$MiningLaser/Cone.monitoring = false
	if not camera:
		camera = get_tree().get_root().get_node_or_null("Level/Camera")
	construction_menu.building_selected.connect(_on_building_selected)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		if construction_menu.visible:
			construction_menu.hide_menu()
			cancel_placement()
		else:
			construction_menu.show_menu()
	
	if is_placing and preview_instance:
		update_preview_position()
		if Input.is_action_just_pressed("action"):
			place_building()

	if not is_placing:
		if Input.is_action_just_pressed("action"):
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

func switch_tool(new_tool):
	current_tool = new_tool
	$Gun.visible = (current_tool == Tool.GUN)
	$MiningLaser.visible = (current_tool == Tool.MINING_LASER)
	$MiningLaser/Cone.monitoring = (current_tool == Tool.MINING_LASER)

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	var level = get_tree().get_root().get_node_or_null("Level")
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
			var level = get_tree().get_root().get_node("Level")
			level.player_ore = body.stored_ore
		elif body.has_method("start_launch"):
			body.start_launch()

func _on_building_selected(scene_path: String, building_name: String):
	construction_menu.hide_menu()
	start_placement(scene_path, building_name)

func start_placement(scene_path: String, building_name: String):
	if is_placing:
		cancel_placement()
	preview_scene_path = scene_path
	preview_building_name = building_name
	preview_instance = load(scene_path).instantiate()
	preview_instance.set_meta("is_preview", true)
	
	var mesh = preview_instance.get_node("MeshInstance3D")
	if mesh:
		mesh.transparency = 0.65
	
	var base_distance = 4.0
	var shape_size_z = 0.0
	var collision_shape = preview_instance.get_node_or_null("CollisionShape3D")
	if collision_shape and collision_shape.shape is BoxShape3D:
		shape_size_z = collision_shape.shape.extents.z
		preview_distance = base_distance + (shape_size_z / 2.0)
	else:
		preview_distance = base_distance
	
	get_tree().get_root().get_node("Level").add_child(preview_instance)
	is_placing = true
	update_preview_position()

func update_preview_position():
	if preview_instance:
		var forward_dir = -transform.basis.z.normalized()
		var preview_pos = global_position + forward_dir * preview_distance
		preview_pos.y = 0
		preview_instance.global_position = preview_pos

func place_building():
	if preview_instance and preview_scene_path:
		var cost = building_configs.get(preview_building_name, {}).get("cost", 0)
		var level = get_tree().get_root().get_node("Level")
		var hq = level.get_node_or_null("Buildings/HeadQuarters")
		if preview_building_name == "hq" or (hq and hq.stored_ore >= cost):
			var withdrawn = cost
			if preview_building_name != "hq":
				withdrawn = hq.withdraw_ore(cost)
			if withdrawn == cost:
				var building = load(preview_scene_path).instantiate()
				building.global_position = preview_instance.global_position
				var mesh = building.get_node("MeshInstance3D")
				if mesh:
					mesh.transparency = 0.0
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
				if building_configs.get(preview_building_name, {}).get("unique", false):
					construction_menu.mark_unique_placed(preview_building_name)
			else:
				print("Failed to withdraw enough ore")
		else:
			print("Not enough ore in HQ to place ", preview_building_name)
		cancel_placement()

func cancel_placement():
	if preview_instance:
		preview_instance.queue_free()
		preview_instance = null
	is_placing = false
	preview_scene_path = ""
	preview_building_name = ""
	preview_distance = 4.0

func set_player(player_node):
	pass

var building_configs = {
	"hq": {"scene": "res://scenes/buildings/headquarters.tscn", "category": "unique", "cost": 0, "unique": true},
	"research": {"scene": "res://scenes/buildings/research_building.tscn", "category": "unique", "cost": 5, "unique": true},
	"ore_mine": {"scene": "res://scenes/buildings/ore_mine.tscn", "category": "ore", "cost": 5},
	"silo": {"scene": "res://scenes/buildings/silo.tscn", "category": "ore", "cost": 10},
	"turret": {"scene": "res://scenes/buildings/turret.tscn", "category": "defenses", "cost": 2},
	"cannon": {"scene": "res://scenes/buildings/cannon.tscn", "category": "defenses", "cost": 8},
	"launch_pad": {"scene": "res://scenes/buildings/launch_pad.tscn", "category": "unique", "cost": 15, "unique": true}
}
