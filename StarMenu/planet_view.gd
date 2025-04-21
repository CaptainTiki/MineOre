extends Node3D

signal perks_selected
signal level_selected(level)

var planet: Node3D

func set_planet(planet_node: Node3D):
	for child in get_children():
		if child != $UI:
			child.queue_free()
	
	planet = planet_node
	planet.position = Vector3.ZERO
	add_child(planet)
	
	$UI/StartLevelButton.connect("pressed", _on_start_level)
	$UI/PerksButton.connect("pressed", _on_perks_button)

func _on_start_level():
	emit_signal("level_selected", planet.get_meta("level_scene", null))

func _on_perks_button():
	emit_signal("perks_selected")
