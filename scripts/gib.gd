extends Node3D

var velocity = Vector3.ZERO

func _physics_process(delta):
	position += velocity * delta
	velocity.y -= 9.8 * delta
	if position.y < 0:
		queue_free()
