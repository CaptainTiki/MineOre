extends CharacterBody3D

var speed = 5.0
var target = null
var view_distance = 10.0
var path = []
var path_index = 0
var path_update_timer = 0.0
var path_update_interval = 0.5
var damage = 1
var attack_rate = 1.0
var attack_timer = 0.0
var health = 5
var separation_distance = 1.0  # Minimum distance to keep from other enemies
var attack_range = 1.5  # Distance to stop from target
@onready var nav_agent = $NavigationAgent3D
@onready var damage_area = $DamageArea

var gib_scene = preload("res://scenes/gib.tscn")

func _ready():
	add_to_group("enemies")
	target = get_tree().get_first_node_in_group("headquarters")
	nav_agent.path_desired_distance = attack_range
	nav_agent.target_desired_distance = attack_range
	nav_agent.avoidance_enabled = true  # Enable avoidance
	nav_agent.max_neighbors = 10  # Consider up to 10 nearby agents
	nav_agent.neighbor_distance = 5.0  # Distance to check for neighbors
	damage_area.body_entered.connect(_on_body_entered)
	damage_area.body_exited.connect(_on_body_exited)
	update_path()

func _physics_process(delta):
	check_for_targets()
	path_update_timer -= delta
	if path_update_timer <= 0:
		update_path()
		path_update_timer = path_update_interval
	
	if target and is_instance_valid(target):
		# Apply separation force
		var separation = compute_separation()
		velocity += separation
		
		if nav_agent.is_navigation_finished():
			velocity = Vector3.ZERO  # Stop moving if at target
		else:
			var next_pos = nav_agent.get_next_path_position()
			var move_dir = (next_pos - global_position).normalized()
			velocity = move_dir * speed
			nav_agent.set_velocity(velocity)  # Update velocity for avoidance
		
		move_and_slide()
		look_at_target(delta)
	
	attack_timer -= delta
	if attack_timer <= 0:
		attack_overlapping_targets()
		attack_timer = attack_rate

func compute_separation() -> Vector3:
	var separation = Vector3.ZERO
	var enemies = get_tree().get_nodes_in_group("enemies")
	var count = 0
	for enemy in enemies:
		if enemy != self and is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < separation_distance and dist > 0:
				var push = (global_position - enemy.global_position).normalized()
				separation += push / max(dist, 0.1)  # Avoid division by zero
				count += 1
	if count > 0:
		separation /= count
		separation *= speed * 0.5  # Scale separation force
	return separation

func check_for_targets():
	var player = get_tree().get_first_node_in_group("player")
	var buildings = get_tree().get_nodes_in_group("turrets") + get_tree().get_nodes_in_group("mines")
	var closest_dist = view_distance + 1
	var new_target = target
	
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < view_distance and dist < closest_dist:
			closest_dist = dist
			new_target = player
	
	for building in buildings:
		if building and is_instance_valid(building):
			var dist = global_position.distance_to(building.global_position)
			if dist < view_distance and dist < closest_dist:
				closest_dist = dist
				new_target = building
	
	if new_target != target:
		target = new_target
		update_path()
		path_update_timer = 0.0

func update_path():
	if target and is_instance_valid(target):
		nav_agent.set_target_position(target.global_position)
		path = []  # Clear manual path since we're using nav_agent
		path_index = 0

func look_at_target(delta):
	if target and is_instance_valid(target):
		var target_pos = target.global_position
		var look_dir = (target_pos - global_position).normalized()
		var target_angle = atan2(-look_dir.x, -look_dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, delta * 5.0)

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	var gib = gib_scene.instantiate()
	gib.global_position = global_position
	get_parent().add_child(gib)
	queue_free()

func _on_body_entered(body):
	if body == target and body.has_method("take_damage"):
		attack_overlapping_targets()

func _on_body_exited(_body):
	pass

func attack_overlapping_targets():
	var bodies = damage_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(damage)

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3):
	velocity = safe_velocity
	move_and_slide()
