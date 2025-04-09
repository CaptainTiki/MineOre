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
	var gib = preload("res://scenes/gib.tscn").instantiate()
	gib.global_position = global_position
	get_parent().add_child(gib)
	queue_free()
