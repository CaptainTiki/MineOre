extends CharacterBody3D

var speed = 2.0
var target = null
var view_distance = 10.0
var path = []
var path_index = 0
var path_update_timer = 0.0
var path_update_interval = 0.5
var damage = 5
var attack_rate = 0.5  # Damage every 1s
var attack_timer = 0.0
var health = 20
@onready var nav_agent = $NavigationAgent3D
@onready var damage_area = $DamageArea

var gib_scene = preload("res://scenes/gib.tscn")

func _ready():
	add_to_group("enemies")
	target = get_tree().get_first_node_in_group("hq")
	if not nav_agent:
		print("Error: NavigationAgent3D not found!")
	if not damage_area:
		print("Error: DamageArea not found!")
	$NavigationAgent3D.path_desired_distance = 1.0
	$NavigationAgent3D.target_desired_distance = 1.0
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
		if path_index < path.size():
			var move_dir = (path[path_index] - global_position).normalized()
			velocity = move_dir * speed
			move_and_slide()
			if global_position.distance_to(path[path_index]) < 1.0:
				path_index += 1
		look_at_target(delta)
	
	attack_timer -= delta
	if attack_timer <= 0:
		attack_overlapping_targets()
		attack_timer = attack_rate

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
		print("Target switched to: ", target.name if target else "null")

func update_path():
	if target and is_instance_valid(target):
		var nav_map = get_world_3d().navigation_map
		if not NavigationServer3D.map_is_active(nav_map):
			print("Error: Navigation map not active!")
			return
		path = NavigationServer3D.map_get_path(
			nav_map,
			global_position,
			target.global_position,
			true
		)
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
	var gib = preload("res://scenes/gib.tscn").instantiate()
	gib.global_position = global_position
	get_parent().add_child(gib)
	queue_free()

func _on_body_entered(body):
	if body == target and body.has_method("take_damage"):
		attack_overlapping_targets()

func _on_body_exited(_body):
	pass  # Could reset timer if needed

func attack_overlapping_targets():
	var bodies = damage_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("Enemy attacked: ", body.name)
