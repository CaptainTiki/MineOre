extends Node3D

signal perks_selected
signal level_selected

@onready var ui_node: Control = $UI
@onready var system_view: SystemView = $"../SystemView"

var planet: Node3D
var active_tweens: Array[Tween] = []
var is_active : bool = false

func enable_view() -> void:
	planet = system_view.planets[system_view.current_planet_index]
	self.show()
	ui_node.visible = true
	set_process(true) # Enable processing
	is_active = true

func disable_view() -> void:
	_reset_planet_positions()

	pass

func _input(event):
	if not is_active:
		return #dont process input if we're not active
	if event.is_action_pressed("select"):
		emit_signal("level_selected")

func set_planet(planet_node: Node3D):
	planet = planet_node
	planet.position = Vector3.ZERO
	add_child(planet)
	
	$UI/StartLevelButton.connect("pressed", _on_start_level)
	$UI/PerksButton.connect("pressed", _on_perks_button)

func _on_start_level():
	emit_signal("level_selected", planet.get_meta("level_scene", null))

func _on_perks_button():
	emit_signal("perks_selected")

func _reset_planet_positions() -> void:
	for i in range(system_view.planets.size()):
		var planet = system_view.planets[i]
		if system_view.current_planet_index >= 0:
			if planet == system_view.planets[system_view.current_planet_index]: 
				#scale our currently selected planet - back to 1
				var planettween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				active_tweens.append(planettween)
				planettween.tween_property(planet, "scale", Vector3(1, 1, 1), 0.25)
				planettween.connect("finished", func(): active_tweens.erase(planettween))
			else: #scale the rest of them back up to 1
				var planettween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				active_tweens.append(planettween)
				# Start parallel tweens
				planettween.parallel().tween_property(planet, "scale", Vector3(1, 1, 1), 0.25)
				var direction = Vector3(1, 0, 0)
				if i < system_view.current_planet_index:
					direction *= -1
				#we use negavative direction here - because we're reversing the movement
				planettween.parallel().tween_property(planet, "position", planet.position + Vector3(10, 0, 0) * -direction, 0.5)
				planettween.connect("finished", func(): active_tweens.erase(planettween))
