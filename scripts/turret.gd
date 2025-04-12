extends StaticBody3D

var bullet_scene = preload("res://scenes/bullet.tscn")
@onready var detection_area = $DetectionArea
@onready var gun = $Gun
@onready var muzzle: Node3D = $Gun/Muzzle

var base_fire_rate = 1.0  # Seconds between shots
var base_rotation_speed = 5.0  # Radians per second for lerp weight
var base_damage = 5.0  # Damage per bullet
var base_health = 5.0

var fire_rate: float
var rotation_speed: float
var damage: float
var health: float

var fire_timer = 0.0
var target = null

func _init():
	fire_rate = Perks.get_modified_stat(base_fire_rate, "turret_fire_rate")
	rotation_speed = Perks.get_modified_stat(base_rotation_speed, "turret_rotation_speed")
	damage = Perks.get_modified_stat(base_damage, "turret_damage")
	health = Perks.get_modified_stat(base_health, "building_health")
	add_to_group("turrets")
	add_to_group("buildings")
	print("Turret initialized with: fire_rate=", fire_rate, " rotation_speed=", rotation_speed, " damage=", damage, " health=", health)

func _ready():
	if not gun:
		print("Error: Gun node not found!")
	if not muzzle:
		print("Error: Muzzle node not found!")
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	fire_timer = fire_rate

func _process(delta):
	if not gun or not muzzle:
		return
	if target and is_instance_valid(target):
		var target_pos = target.global_position
		var look_dir = (target_pos - gun.global_position).normalized()
		var target_angle = atan2(-look_dir.x, -look_dir.z)
		gun.rotation.y = lerp_angle(gun.rotation.y, target_angle, delta * rotation_speed)
		
		fire_timer -= delta
		if fire_timer <= 0:
			shoot_bullet()
			fire_timer = fire_rate
	else:
		var enemies = detection_area.get_overlapping_bodies()
		if enemies.size() > 0:
			target = enemies[0]
			fire_timer = fire_rate
			print("New target acquired, timer reset to: ", fire_rate)

func _on_body_entered(body):
	if body.is_in_group("enemies") and not target:
		target = body
		fire_timer = fire_rate

func _on_body_exited(body):
	if body == target:
		target = null

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	get_tree().get_root().get_node("Level").add_child(bullet)
	bullet.global_position = muzzle.global_position
	var bullet_speed = 20.0
	var forward_dir = -gun.global_transform.basis.z.normalized()
	bullet.velocity = forward_dir * bullet_speed
	bullet.damage = damage  # Pass damage to bullet
	print("Turret fired at: ", target.global_position, " Bullet pos: ", bullet.global_position)

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()
	print("Turret health: ", health)
