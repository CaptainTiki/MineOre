extends Node3D

signal perks_selected
signal level_selected

@onready var ui_node: Control = $UI
@onready var system_view: SystemView = $"../SystemView"
@onready var planets_node: Node3D = $"../Planets"

var planet: Node3D
var active_tweens: Array[Tween] = []
var is_active : bool = false

func enable_view() -> void:
	planet = system_view.planets[system_view.current_planet_index]
	self.show()
	ui_node.visible = true
	$UI/PlanetInfoPanel.show()
	if planet:
		planet.visible = true
		print("PlanetView: Enabling view, planet ", planet.name, " visible: ", planet.visible, " at position: ", planet.global_transform.origin)
	else:
		print("PlanetView: Error - No planet set in enable_view")
	set_process(true)
	is_active = true

func disable_view() -> void:
	_reset_planet_positions()
	$UI/PlanetInfoPanel.hide()
	if planet:
		planet.visible = true
		print("PlanetView: Disabling view, planet ", planet.name, " visible: ", planet.visible)
	is_active = false
	set_process(false)

func _input(event):
	if not is_active:
		return
	if event.is_action_pressed("select"):
		emit_signal("level_selected")

func set_planet(planet_node: Node3D):
	planet = planet_node
	if planet:
		planet.visible = true
		print("PlanetView: Setting planet ", planet.name, " visible: ", planet.visible, " at position: ", planet.global_transform.origin)
	else:
		print("PlanetView: Error - No planet node provided in set_planet")
	
	$UI/PlanetInfoPanel/InfoContainer/PlanetNameLabel.text = "Planet: " + planet.get_meta("name", "Unknown Planet")
	$UI/PlanetInfoPanel/InfoContainer/DescriptionLabel.text = "Description: A rocky planet with moderate gravity."
	$UI/PlanetInfoPanel/InfoContainer/EnvironmentLabel.text = "Environment: Temperate, breathable atmosphere."
	$UI/PlanetInfoPanel/InfoContainer/DifficultyLabel.text = "Difficulty: Medium"

func _on_start_level():
	emit_signal("level_selected", planet.get_meta("level_scene", null))

func _on_perks_button():
	emit_signal("perks_selected")

func _on_accept_button():
	$UI/PlanetInfoPanel.hide()
	emit_signal("perks_selected")

func _reset_planet_positions() -> void:
	for i in range(system_view.planets.size()):
		var planet = system_view.planets[i]
		if not is_instance_valid(planet):
			print("PlanetView: Invalid planet at index ", i)
			continue
		var planettween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		active_tweens.append(planettween)
		if system_view.current_planet_index >= 0 and planet == system_view.planets[system_view.current_planet_index]: 
			planettween.tween_property(planet, "scale", Vector3(1, 1, 1), 0.25)
			planettween.tween_callback(func(): 
				if is_instance_valid(planet):
					print("PlanetView: Reset selected planet ", planet.name, " to scale (1, 1, 1)")
			)
		else:
			planettween.parallel().tween_property(planet, "scale", Vector3(1, 1, 1), 0.25)
			var direction = Vector3(1, 0, 0)
			if i < system_view.current_planet_index:
				direction *= -1
			planettween.parallel().tween_property(planet, "global_position", planet.global_position + Vector3(10, 0, 0) * -direction, 0.5)
			planettween.tween_callback(func(): 
				if is_instance_valid(planet):
					print("PlanetView: Reset non-selected planet ", planet.name, " to scale (1, 1, 1), moved")
			)
		planettween.connect("finished", func(): 
			active_tweens.erase(planettween)
			if is_instance_valid(planet):
				print("PlanetView: Tween finished for planet ", planet.name)
		)
