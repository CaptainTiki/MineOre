# system_view.gd
extends Node3D

var current_system: Star_System
var star = null  # To track the star node for exclusion in _input

func set_system(system: Star_System):
	current_system = system
	for child in get_children():
		if child != $UI:
			child.queue_free()
	var planet_position = Vector3(15, 0, 0)
	var star_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	star_tween.tween_property(current_system.star, "scale", Vector3(5, 5, 5), 0.5)
	for planet_scene in current_system.system_resource.planets:
		var planet = planet_scene.instantiate()
		planet.position = planet_position
		planet.scale = Vector3(0, 0, 0)
		add_child(planet)
		var planet_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		planet_tween.tween_property(planet, "scale", Vector3(1, 1, 1), 0.5)
		planet_position += Vector3(8, 0, 0)

func exit_view():
	var star_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	star_tween.tween_property(current_system.star, "scale", Vector3(1, 1, 1), 0.5)
	for planet in get_children():
		if planet is Node3D and planet != $UI:
			var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(planet, "scale", Vector3(0, 0, 0), 0.5)
	await get_tree().create_timer(0.5).timeout
