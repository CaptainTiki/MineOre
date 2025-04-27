extends Node3D

signal planet_confirm

@onready var ui_node: Control = $UI
@onready var system_view: SystemView = $"../SystemView"
@onready var planets_node: Node3D = $"../Planets"

var planet: Node3D
var active_tweens: Array[Tween] = []
var is_active : bool = false
var input_select : bool = false #this tells us if the player is ready to select perks, or is canceling during disable_view

func _ready() -> void:
	ui_node.visible = false

func enable_view() -> void:
	planet = system_view.planets[system_view.current_planet_index]
	self.show()
	ui_node.visible = true
	$UI/PlanetInfoPanel.show()
	set_process(true)
	is_active = true
	input_select = false #make sure to reset this variable when we come back to planet_view

func disable_view() -> void:
	_reset_planet_positions()
	ui_node.visible = false
	is_active = false
	set_process(false)

func _input(event):
	if not is_active:
		return
	if event.is_action_pressed("select"):
		input_select = true #user is moving to perks, not canceling
		emit_signal("planet_confirm")

func set_planet(planet_node: Node3D):
	planet = planet_node
	if planet:
		planet.visible = true
	
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
		var new_planet = system_view.planets[i]
		if not is_instance_valid(new_planet):
			continue
		var planettween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		active_tweens.append(planettween)
		if system_view.current_planet_index >= 0 and new_planet == system_view.planets[system_view.current_planet_index] and not input_select: 
			planettween.tween_property(new_planet, "scale", Vector3(1, 1, 1), 0.25)
		elif system_view.current_planet_index >= 0 and new_planet == system_view.planets[system_view.current_planet_index] and  input_select: 
			continue #don't do anything to our selected new_planet - just skip out of this one
		else:
			planettween.parallel().tween_property(new_planet, "scale", Vector3(1, 1, 1), 0.25)
			var direction = Vector3(1, 0, 0)
			if i < system_view.current_planet_index:
				direction *= -1
			planettween.parallel().tween_property(new_planet, "global_position", new_planet.global_position + Vector3(10, 0, 0) * -direction, 0.5)
		planettween.connect("finished", func(): 
			active_tweens.erase(planettween)
		)
