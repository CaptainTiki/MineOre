extends CharacterBody3D

var gib_scene = preload("res://scenes/gib.tscn")
var health = 5

func _physics_process(delta):
	var base = get_tree().get_root().get_node("Main/Buildings/HeadQuarters")
	var direction = (base.global_position - global_position).normalized()
	velocity = direction * 2.0
	move_and_slide()
	
	if global_position.distance_to(base.global_position) < 1.5:
		base.take_damage(1)
		die()

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	for i in 5:
		var gib = gib_scene.instantiate()
		gib.position = global_position
		gib.velocity = Vector3(randf_range(-1, 1), randf_range(1, 3), randf_range(-1, 1))
		get_tree().get_root().get_node("Main/Particles").add_child(gib)
	queue_free()
