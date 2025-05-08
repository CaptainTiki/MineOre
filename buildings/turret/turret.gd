# res://buildings/turret/turret.gd
extends Building
class_name Turret

var bullet_scene = preload("res://scenes/he_bullet.tscn")
@onready var detection_area = $DetectionArea
@onready var gun = $Gun
@onready var muzzle: Node3D = $Gun/Muzzle

var base_fire_rate = 0.75
var base_rotation_speed = 6.0
var base_damage = 20.0
var detection_range = 10.0  # Matches enemy's view_distance for balance

var fire_rate: float
var rotation_speed: float
var damage: float
var fire_timer = 0.0
var current_target: Node = null

func _ready():
	super._ready()
	add_to_group("turrets")
	fire_rate = PerksManager.get_modified_stat(base_fire_rate, "turret_fire_rate")
	rotation_speed = PerksManager.get_modified_stat(base_rotation_speed, "turret_rotation_speed")
	damage = PerksManager.get_modified_stat(base_damage, "turret_damage")
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	fire_timer = fire_rate
	select_target()

func _process(delta):
	super._process(delta)
	if not gun or not muzzle:
		return
	if current_target and is_instance_valid(current_target):
		var target_pos = current_target.global_position
		var look_dir = (target_pos - gun.global_position).normalized()
		var target_angle = atan2(-look_dir.x, -look_dir.z)
		gun.rotation.y = lerp_angle(gun.rotation.y, target_angle, delta * rotation_speed)
		fire_timer -= delta
		if fire_timer <= 0:
			shoot_bullet()
			fire_timer = fire_rate
	else:
		select_target()

func set_target(new_target: Node):
	if current_target and is_instance_valid(current_target):
		current_target.remove_targeting_turret(self)
		if current_target.has_signal("died"):
			current_target.disconnect("died", _on_target_died)
	current_target = new_target
	if current_target:
		current_target.add_targeting_turret(self)
		if current_target.has_signal("died"):
			current_target.connect("died", _on_target_died)

func _on_target_died():
	current_target = null
	select_target()

func _on_body_entered(body):
	super._on_body_entered(body)
	if body.is_in_group("enemies"):
		if not current_target or should_switch_target(body):
			select_target()

func _on_body_exited(body):
	super._on_body_exited(body)
	if body == current_target:
		current_target = null
		select_target()

func is_potential_target(body: Node) -> bool:
	return body.is_in_group("enemies")

func should_switch_target(new_body: Node) -> bool:
	if not current_target:
		return true
	return new_body.targeted_by_turrets.size() < current_target.targeted_by_turrets.size()

func select_target():
	var potential_targets = detection_area.get_overlapping_bodies().filter(func(body):
		return is_potential_target(body)
	)
	if potential_targets.is_empty():
		set_target(null)
		return
	potential_targets.sort_custom(func(a, b):
		return a.targeted_by_turrets.size() < b.targeted_by_turrets.size()
	)
	set_target(potential_targets[0])

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	get_tree().get_root().get_node("Level").add_child(bullet)
	bullet.global_position = muzzle.global_position
	var bullet_speed = 20.0
	var forward_dir = -gun.global_transform.basis.z.normalized()
	bullet.velocity = forward_dir * bullet_speed
	bullet.damage = damage

func _on_destroyed():
	if current_target and is_instance_valid(current_target):
		current_target.remove_targeting_turret(self)
	super._on_destroyed()
