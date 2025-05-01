# res://scripts/enemy.gd
extends CharacterBody3D
class_name Enemy

signal died

var speed = 3.5
var view_distance = 10.0
var damage = 6
var attack_rate = 1.0
var attack_timer = 0.0
var health = 25
var separation_distance = 3.0
var attack_range = 1.5
var is_alive = false
var current_target: Node = null
var path_update_timer = 0.0
var path_update_interval = 0.5
var targeted_by_turrets: Array[Node] = []  # Array to track turrets targeting this enemy

@onready var nav_agent = $NavigationAgent3D
@onready var damage_area = $DamageArea
@onready var sight_area = $SightArea  # Area3D for vision detection

var gib_scene = preload("res://scenes/gib.tscn")

func _ready():
	add_to_group("enemies")
	nav_agent.path_desired_distance = attack_range
	nav_agent.target_desired_distance = attack_range
	nav_agent.avoidance_enabled = true
	nav_agent.max_neighbors = 10
	nav_agent.neighbor_distance = 5.0
	damage_area.body_entered.connect(_on_body_entered)
	damage_area.body_exited.connect(_on_body_exited)
	sight_area.body_entered.connect(_on_sight_area_body_entered)
	is_alive = false
	set_physics_process(false)
	set_process(false)
	select_target()

func reset(pos: Vector3):
	global_position = pos
	health = 25
	velocity = Vector3.ZERO
	current_target = null
	targeted_by_turrets.clear()
	path_update_timer = 0.0
	attack_timer = 0.0
	visible = true
	set_physics_process(true)
	set_process(true)
	select_target()
	is_alive = true

func _physics_process(delta):
	path_update_timer -= delta
	if path_update_timer <= 0:
		update_path()
		path_update_timer = path_update_interval
	
	if current_target and is_instance_valid(current_target):
		var separation = compute_separation()
		velocity += separation
		
		if nav_agent.is_navigation_finished():
			velocity = Vector3.ZERO
		else:
			var next_pos = nav_agent.get_next_path_position()
			var move_dir = (next_pos - global_position).normalized()
			velocity = move_dir * speed
			nav_agent.set_velocity(velocity)
		
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
		if enemy != self and is_instance_valid(enemy) and enemy.visible:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < separation_distance and dist > 0:
				var push = (global_position - enemy.global_position).normalized()
				separation += push / max(dist, 0.1)
				count += 1
	if count > 0:
		separation /= count
		separation *= speed * 0.5
	return separation

func set_target(new_target: Node):
	if current_target and is_instance_valid(current_target):
		current_target.remove_targeting_enemy(self)
		if current_target.has_signal("destroyed"):
			current_target.disconnect("destroyed", _on_target_destroyed)
	current_target = new_target
	if current_target:
		current_target.add_targeting_enemy(self)
		if current_target.has_signal("destroyed"):
			current_target.connect("destroyed", _on_target_destroyed)

func _on_target_destroyed(_building_name: String = ""):
	var hq = get_tree().get_first_node_in_group("headquarters")
	if hq:
		current_target = hq
	else:
		current_target = null
	select_target()

func _on_sight_area_body_entered(body: Node):
	if body == self or not is_potential_target(body):
		return
	if should_switch_target(body):
		select_target()

func is_potential_target(body: Node) -> bool:
	return body.is_in_group("buildings") or body.is_in_group("player")

func should_switch_target(new_body: Node) -> bool:
	if not current_target:
		return true
	return new_body.targeted_by.size() < current_target.targeted_by.size()

func select_target():
	var potential_targets = sight_area.get_overlapping_bodies().filter(func(body):
		return is_potential_target(body)
	)
	if potential_targets.is_empty():
		var hq = get_tree().get_first_node_in_group("headquarters")
		if hq:
			set_target(hq)
		else:
			set_target(null)
		return
	potential_targets.sort_custom(func(a, b):
		return a.targeted_by.size() < b.targeted_by.size()
	)
	set_target(potential_targets[0])

func update_path():
	if current_target and is_instance_valid(current_target):
		nav_agent.set_target_position(current_target.global_position)

func look_at_target(delta):
	if current_target and is_instance_valid(current_target):
		var target_pos = current_target.global_position
		var look_dir = (target_pos - global_position).normalized()
		var target_angle = atan2(-look_dir.x, -look_dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, delta * 5.0)

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	if current_target and is_instance_valid(current_target):
		current_target.remove_targeting_enemy(self)
	for turret in targeted_by_turrets.duplicate():
		if is_instance_valid(turret):
			turret.set_target(null)
	targeted_by_turrets.clear()
	var gib = gib_scene.instantiate()
	gib.global_position = global_position
	get_parent().add_child(gib)
	global_position = Vector3(999, 999, 999)
	visible = false
	set_physics_process(false)
	emit_signal("died")
	is_alive = false
	# Don't queue_free(); returned to pool by SpawnerManager

func _on_body_entered(body):
	if body == current_target and body.has_method("take_damage"):
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

# Turret targeting management
func add_targeting_turret(turret: Node):
	if not targeted_by_turrets.has(turret):
		targeted_by_turrets.append(turret)

func remove_targeting_turret(turret: Node):
	targeted_by_turrets.erase(turret)
