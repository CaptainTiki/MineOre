extends StaticBody3D

signal silo_destroyed

var base_health = 5.0
var health: float

func _init():
	health = base_health
	add_to_group("buildings")
	add_to_group("silo")
	print("Silo initialized with: health=", health)

func _ready():
	pass

func take_damage(amount):
	health -= amount
	if health <= 0:
		emit_signal("silo_destroyed")
		var hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")
		if hq:
			hq.remove_silo()
		queue_free()
	print("Silo health: ", health)
