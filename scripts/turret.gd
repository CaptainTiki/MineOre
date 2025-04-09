extends StaticBody3D

@onready var weapon = $Weapon
@onready var muzzle = $Weapon/Muzzle
@onready var detection_area = $DetectionArea
var bullet_scene = preload("res://scenes/bullet.tscn")
var effective_range = 5.0  # Matches DetectionArea radius
var fire_rate = 1.0  # Shots per second
var time_since_last_shot = 0.0

func _ready():
	# Snap to ground (Y=0 plane)
	var plane = Plane(Vector3.UP, 0)
	var ray_origin = global_position + Vector3(0, 1, 0)  # Start above
	var ray_dir = Vector3.DOWN
	var intersect = plane.intersects_ray(ray_origin, ray_dir)
	if intersect:
		global_position = intersect

func _physics_process(delta):
	# Update shooting cooldown
	time_since_last_shot += delta
	
	# Find nearest enemy
	var enemies = detection_area.get_overlapping_bodies()
	var nearest_enemy = null
	var min_distance = effective_range + 1  # Beyond range to start
	
	for enemy in enemies:
		if enemy.is_in_group("enemies"):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < min_distance:
				min_distance = distance
				nearest_enemy = enemy
	
	# Rotate weapon to nearest enemy if in range
	if nearest_enemy and min_distance <= effective_range:
		var target_pos = nearest_enemy.global_position
		weapon.look_at(target_pos, Vector3.UP)
		# Shoot if cooldown elapsed
		if time_since_last_shot >= 1.0 / fire_rate:
			shoot_bullet(target_pos)
			time_since_last_shot = 0.0

func shoot_bullet(target_pos):
	var bullet = bullet_scene.instantiate()
	get_tree().get_root().get_node("Main").add_child(bullet)
	bullet.global_position = muzzle.global_position
	var direction = (target_pos - muzzle.global_position).normalized()
	bullet.velocity = direction * 20.0  # Match player bullet speed
