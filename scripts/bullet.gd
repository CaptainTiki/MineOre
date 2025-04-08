extends Area3D

var damage = 20
var lifetime = 2.0
var velocity = Vector3.ZERO  # Set by Player when spawned

func _ready():
	# Connect signal in editor or here; we'll do it in code for now
	if not is_connected("body_entered", _on_body_entered):
		body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	# Move manually based on velocity
	global_position += velocity * delta

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		print("Bullet hit enemy: ", body.name)
		body.take_damage(damage)
		queue_free()
	else:
		print("Bullet hit something else: ", body.name)
