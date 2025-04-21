extends Node3D

signal planet_selected(planet)

var current_system: StarSystemResource

func set_system(resource: StarSystemResource):
	current_system = resource
	for child in get_children():
		if child != $UI:
			child.queue_free()
	
	var star = resource.star_scene.instantiate()
	star.position = Vector3.ZERO
	add_child(star)
	
	for planet_scene in resource.planets:
		var planet = planet_scene.instantiate()
		planet.position = Vector3(randi_range(-5, 5), randi_range(-5, 5), 0)
		planet.connect("input_event", _on_planet_input.bind(planet))
		add_child(planet)

func _on_planet_input(_camera, event: InputEvent, _position, _normal, _shape_idx, planet: Node3D):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("planet_selected", planet)
