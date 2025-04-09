extends StaticBody3D

func take_damage(amount):
	var main = get_tree().get_root().get_node("Main")
	
	main.base_hp -= amount
