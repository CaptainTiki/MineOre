extends CharacterBody3D

signal ore_carried(amount)
signal ore_deposited(amount)
signal hq_placed
signal turret_placed(position)
signal mine_placed(position)

enum Tool { NONE, GUN, MINING_LASER, TURRET, MINE }
var current_tool = Tool.NONE
var speed = 5.0
var bullet_scene = preload("res://scenes/bullet.tscn")
var turret_scene = preload("res://scenes/turret.tscn")
var mine_scene = preload("res://scenes/ore_mine.tscn")
var headquarters_scene = preload("res://scenes/headquarters.tscn")
var is_placing_hq = true
var carry_capacity = 20
var carried_ore = 0

@onready var camera = get_node_or_null("../Camera")

func _ready():
	# Clear input to prevent carryover from star map
	Input.action_release("action")
	
	add_to_group("player")
	$Gun.visible = false
	$MiningLaser.visible = false
	$MiningLaser/Cone.monitoring = false
	if not camera:
		camera = get_tree().get_root().get_node_or_null("Level/Camera")
		if not camera:
			print("Error: Camera not found at ../Camera or /root/Level/Camera!")
	if not $InteractArea:
		print("Error: InteractArea not found in player scene!")
	else:
		print("InteractArea found, radius: ", $InteractArea.get_node("CollisionShape3D").shape.radius)
	print("Player ready, placing HQ: ", is_placing_hq)

func _process(delta: float) -> void:
	if is_placing_hq:
		if Input.is_action_just_pressed("action"):
			print("Action pressed, placing HQ at: ", global_position)
			place_headquarters()
	else:
		if Input.is_action_just_pressed("action"):
			match current_tool:
				Tool.GUN:
					shoot_bullet()
				Tool.MINING_LASER:
					mine_ore()
				Tool.TURRET:
					try_place_turret()
				Tool.MINE:
					try_place_mine()
					
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
	if not is_placing_hq:
		if event.is_action_pressed("tool_gun"):
			switch_tool(Tool.GUN)
		elif event.is_action_pressed("tool_mining_laser"):
			switch_tool(Tool.MINING_LASER)
		elif event.is_action_pressed("tool_turret"):
			switch_tool(Tool.TURRET)
		elif event.is_action_pressed("tool_mine"):
			switch_tool(Tool.MINE)

func switch_tool(new_tool):
	current_tool = new_tool
	$Gun.visible = (current_tool == Tool.GUN)
	$MiningLaser.visible = (current_tool == Tool.MINING_LASER)
	$MiningLaser/Cone.monitoring = (current_tool == Tool.MINING_LASER)
	print("Tool switched to: ", current_tool, " Monitoring: ", $MiningLaser/Cone.monitoring)

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	var level = get_tree().get_root().get_node_or_null("Level")
	if not level:
		print("Error: Level node not found at /root/Level!")
		return
	level.add_child(bullet)
	if $Gun == null or not $Gun.is_inside_tree():
		print("Error: $Gun is null or not in tree!")
		bullet.global_position = global_position
	else:
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
	if not $InteractArea:
		print("Error: InteractArea is null!")
		return
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

func try_place_turret():
	if not camera:
		print("Error: Camera is null in try_place_turret!")
		return
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var plane = Plane(Vector3.UP, 0)
	var intersect = plane.intersects_ray(ray_origin, ray_dir)
	if intersect:
		emit_signal("turret_placed", intersect)

func try_place_mine():
	if not camera:
		print("Error: Camera is null in try_place_mine!")
		return
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var plane = Plane(Vector3.UP, 0)
	var intersect = plane.intersects_ray(ray_origin, ray_dir)
	if intersect:
		emit_signal("mine_placed", intersect)

func place_headquarters():
	if not camera:
		print("Error: Camera is null in place_headquarters!")
		return
	var hq = headquarters_scene.instantiate()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var plane = Plane(Vector3.UP, 0)
	var intersect = plane.intersects_ray(ray_origin, ray_dir)
	if intersect:
		hq.global_position = intersect
		var level = get_tree().get_root().get_node_or_null("Level")
		if not level:
			print("Error: Level node not found at /root/Level!")
			return
		level.add_child(hq)
		is_placing_hq = false
		emit_signal("hq_placed")
		print("HQ placed at: ", intersect)

func set_player(player_node):
	pass
