extends StaticBody3D

func _process(delta):
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) < 5:
			if randf() < 0.1:
				if enemy.has_method("die"):
					enemy.die()
