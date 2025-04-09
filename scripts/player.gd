extends CharacterBody3D

signal mined_ore

enum Tool { NONE, GUN, MINING_LASER, TURRET }
var current_tool = Tool.NONE
var speed = 5.0
var bullet_scene = preload("res://scenes/bullet.tscn")
var turret_scene = preload("res://scenes/turret.tscn")
var is_orbiting = false

func _ready():
	$Gun.visible = false
	$MiningLaser.visible = false
	$MiningLaser/Cone.monitoring = false
	var camera = get_tree().get_root().get_node("Main/Camera")
	camera.connect("tree_entered", _on_camera_ready)

func _on_camera_ready():
	var camera = get_tree().get_root().get_node("Main/Camera")
	if camera:
		print("Player connected to camera")

func _physics_process(delta):
	# Movement input
	var input = Vector3.ZERO
	if Input.is_action_pressed("move_forward"): input.z += 1  # Swapped
	if Input.is_action_pressed("move_backward"): input.z -= 1  # Swapped
	if Input.is_action_pressed("move_left"): input.x -= 1
	if Input.is_action_pressed("move_right"): input.x += 1
	
	# Transform input based on player's rotation
	var forward = -transform.basis.z.normalized()
	var right = transform.basis.x.normalized()
	var move_dir = (forward * input.z + right * input.x).normalized()
	velocity = move_dir * speed
	move_and_slide()
	
	# Clamp position to larger ground
	position.x = clamp(position.x, -50, 50)
	position.z = clamp(position.z, -50, 50)
	
	# Rotation logic
	var camera = get_tree().get_root().get_node("Main/Camera")
	if camera:
		is_orbiting = camera.is_orbiting
		if is_orbiting:
			var camera_pos = camera.global_position
			var direction = (global_position - camera_pos).normalized()
			direction.y = 0
			if direction.length() > 0:
				look_at(global_position + direction, Vector3.UP)
		else:
			var mouse_pos = get_viewport().get_mouse_position()
			var ray_origin = camera.project_ray_origin(mouse_pos)
			var ray_dir = camera.project_ray_normal(mouse_pos)
			var plane = Plane(Vector3.UP, 0)
			var intersect = plane.intersects_ray(ray_origin, ray_dir)
			if intersect:
				var look_pos = intersect
				look_at(Vector3(look_pos.x, global_position.y, look_pos.z), Vector3.UP)

	# Tool actions
	if Input.is_action_just_pressed("action"):
		match current_tool:
			Tool.GUN:
				shoot_bullet()
			Tool.MINING_LASER:
				mine_ore()
			Tool.TURRET:
				place_turret()

func _input(event):
	if event.is_action_pressed("tool_gun"):
		switch_tool(Tool.GUN)
	elif event.is_action_pressed("tool_mining_laser"):
		switch_tool(Tool.MINING_LASER)
	elif event.is_action_pressed("tool_turret"):
		switch_tool(Tool.TURRET)

func switch_tool(new_tool):
	current_tool = new_tool
	$Gun.visible = (current_tool == Tool.GUN)
	$MiningLaser.visible = (current_tool == Tool.MINING_LASER)
	$MiningLaser/Cone.monitoring = (current_tool == Tool.MINING_LASER)
	print("Tool switched to: ", current_tool, " Monitoring: ", $MiningLaser/Cone.monitoring)

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	get_tree().get_root().get_node("Main").add_child(bullet)
	if $Gun == null or not $Gun.is_inside_tree():
		print("Error: $Gun is null or not in tree!")
		bullet.global_position = global_position
	else:
		bullet.global_position = $Gun.global_position
	var bullet_speed = 20.0
	var forward_dir = -transform.basis.z.normalized()
	bullet.velocity = forward_dir * bullet_speed

func mine_ore():
	var ores = $MiningLaser/Cone.get_overlapping_bodies()
	print("Overlapping bodies: ", ores.size())
	for ore in ores:
		print("Body: ", ore.name, " Groups: ", ore.get_groups())
		if ore.is_in_group("ores"):
			print("Mining ore: ", ore.name)
			ore.queue_free()
			emit_signal("mined_ore")

func place_turret():
	var turret = turret_scene.instantiate()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = get_tree().get_root().get_node("Main/Camera").project_ray_origin(mouse_pos)
	var ray_dir = get_tree().get_root().get_node("Main/Camera").project_ray_normal(mouse_pos)
	var plane = Plane(Vector3.UP, 0)
	var intersect = plane.intersects_ray(ray_origin, ray_dir)
	if intersect:
		turret.global_position = intersect
		get_tree().get_root().get_node("Main").add_child(turret)
