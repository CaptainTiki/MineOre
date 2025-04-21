extends Node3D

signal perks_confirmed

var planet: Node3D

func set_planet(planet_node: Node3D):
	planet = planet_node
	# TODO: Populate UI with available perks (e.g., from GameState or planet meta)
	$UI/ConfirmButton.connect("pressed", _on_confirm)

func _on_confirm():
	# TODO: Save selected perks to GameState
	emit_signal("perks_confirmed")
