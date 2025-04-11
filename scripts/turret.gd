extends StaticBody3D

var bullet_scene = preload("res://scenes/bullet.tscn")
@onready var detection_area = $DetectionArea
@onready var gun = $Gun
@onready var muzzle: Node3D = $Gun/Muzzle
var fire_rate = 1.0
var fire_timer = 0.0
var target = null
var health = 5

func _ready():
	if not gun:
		print("Error: Gun node not found!")
	if not muzzle:
		print("Error: Muzzle node not found!")
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _process(delta):
	if not gun or not muzzle:
		return
	if target and is_instance_valid(target):
		var target_pos = target.global_position
		var look_dir = (target_pos - gun.global_position).normalized()
		var target_angle = atan2(-look_dir.x, -look_dir.z)
		gun.rotation.y = lerp_angle(gun.rotation.y, target_angle, delta * 5.0)
		
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
		print("Enemy entered, timer set to: ", fire_rate)

func _on_body_exited(body):
	if body == target:
		target = null
		print("Target lost")

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	get_tree().get_root().get_node("Main/Level").add_child(bullet)
	bullet.global_position = muzzle.global_position
	var bullet_speed = 20.0
	var forward_dir = -gun.global_transform.basis.z.normalized()
	bullet.velocity = forward_dir * bullet_speed
	print("Turret fired at: ", target.global_position, " Bullet pos: ", bullet.global_position)

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()
	print("Turret health: ", health)
