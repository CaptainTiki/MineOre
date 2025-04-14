extends Area3D

var velocity = Vector3.ZERO
var damage = 50
var lifetime = 5.0

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	global_position += velocity * delta
	if velocity != Vector3.ZERO:
		var forward = velocity.normalized()
		look_at(global_position + forward, Vector3.UP)

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(damage)
		queue_free()
