extends CharacterBody3D

signal mined_ore

enum Tool { NONE, GUN, MINING_LASER }
var current_tool = Tool.NONE
var speed = 5.0
var bullet_scene = preload("res://scenes/bullet.tscn")

func _ready():
	$Gun.visible = false
	$MiningLaser.visible = false
	$MiningLaser/Cone.monitoring = false

func _physics_process(delta):
	# Movement
	var input = Vector3.ZERO
	if Input.is_action_pressed("move_forward"): input.z -= 1
	if Input.is_action_pressed("move_backward"): input.z += 1
	if Input.is_action_pressed("move_left"): input.x -= 1
	if Input.is_action_pressed("move_right"): input.x += 1
	velocity = input.normalized() * speed
	move_and_slide()
	
	# Constrain to map
	position.x = clamp(position.x, -9, 9)
	position.z = clamp(position.z, -9, 9)
	
	# Face mouse cursor
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = get_tree().root.get_camera_3d().project_ray_origin(mouse_pos)
	var ray_dir = get_tree().root.get_camera_3d().project_ray_normal(mouse_pos)
	var plane = Plane(Vector3.UP, 0)
	var intersect = plane.intersects_ray(ray_origin, ray_dir)
	if intersect:
		var look_pos = intersect
		look_at(Vector3(look_pos.x, global_position.y, look_pos.z), Vector3.UP)

	# Tool usage
	if Input.is_action_just_pressed("action"):
		match current_tool:
			Tool.GUN:
				shoot_bullet()
			Tool.MINING_LASER:
				mine_ore()

func _input(event):
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
	# Add to scene tree first
	get_tree().get_root().get_node("Main").add_child(bullet)
	# Safety check for $Gun
	if $Gun == null or not $Gun.is_inside_tree():
		print("Error: $Gun is null or not in tree!")
		bullet.global_position = global_position  # Fallback to player position
	else:
		bullet.global_position = $Gun.global_position
	var bullet_speed = 20.0
	var forward_dir = -transform.basis.z.normalized()
	bullet.velocity = forward_dir * bullet_speed

func mine_ore():
	var ores = $MiningLaser/Cone.get_overlapping_bodies()
	for ore in ores:
		if ore.is_in_group("ores"):
			ore.queue_free()
			emit_signal("mined_ore")
