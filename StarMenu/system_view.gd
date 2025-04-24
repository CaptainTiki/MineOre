#system_view.gd
extends Node3D
class_name SystemView

signal planet_selected

var current_system: Star_System
var star = null  # To track the star node for exclusion in _input
var highlight_sprite: Sprite3D = null
var current_planet_index: int = 1 #we set this to 1 - because we don't want to include the star
var planets: Array = []

var active_tweens: Array[Tween] = []
var is_active : bool = false

@onready var planet_info_panel = $UI/PlanetInfoPanel
@onready var planet_name_label = $UI/PlanetInfoPanel/InfoContainer/PlanetNameLabel
@onready var difficulty_label = $UI/PlanetInfoPanel/InfoContainer/DifficultyLabel
@onready var type_label = $UI/PlanetInfoPanel/InfoContainer/TypeLabel
@onready var locked_label = $UI/PlanetInfoPanel/InfoContainer/LockedLabel
@onready var ui_node: Control = $UI

@onready var star_menu: StarMenu = $".."

# 2D lines for connection to info panel
var canvas_layer: CanvasLayer
var vertical_line_2d: Line2D
var panel_line_2d: Line2D

func _ready():
	# Initialize highlight sprite
	highlight_sprite = Sprite3D.new()
	highlight_sprite.texture = preload("res://assets/ring.png")
	highlight_sprite.scale = Vector3(1.0, 1.0, 1.0)  # Scaled down for closer view
	highlight_sprite.translate(Vector3(0, 0.5, 0))
	highlight_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	highlight_sprite.visible = false
	add_child(highlight_sprite)
	
	# Initialize canvas layer for 2D lines
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	vertical_line_2d = Line2D.new()
	vertical_line_2d.width = 2
	vertical_line_2d.default_color = Color(1, 0, 0)  # Red for visibility
	vertical_line_2d.visible = false
	canvas_layer.add_child(vertical_line_2d)
	
	panel_line_2d = Line2D.new()
	panel_line_2d.width = 2
	panel_line_2d.default_color = Color(1, 0, 0)
	panel_line_2d.visible = false
	canvas_layer.add_child(panel_line_2d)
	
	# Position and hide info panel initially
	planet_info_panel.position = Vector2(get_viewport().size.x - 320, 20)
	planet_info_panel.visible = false

func set_system(system: Star_System):
	current_system = system
	star = current_system.star
	var planet_position = Vector3(15, 0, 0)
	var startween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	startween.tween_property(star, "scale", Vector3(5, 5, 5), 0.5)
	active_tweens.append(startween)
	startween.connect("finished", func(): active_tweens.erase(startween))
	if planets.size() <= 0: #this is the first time - create our planets
		for planet_scene in current_system.system_resource.planets:
			var planet = planet_scene.instantiate()
			planet.position = planet_position
			planet.scale = Vector3(0.01, 0.01, 0.01)
			add_child(planet)
			planets.append(planet)
			var planet_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			active_tweens.append(planet_tween)
			planet_tween.tween_property(planet, "scale", Vector3(1, 1, 1), 0.5)
			planet_tween.connect("finished", func(): active_tweens.erase(planet_tween))
			planet_position += Vector3(8, 0, 0)

func enable_view() -> void:
	global_position = current_system.global_position
	canvas_layer.visible = true
	self.show()
	self.set_process(true)
	ui_node.visible = true
	is_active = true
	pass

func disable_view() -> void:
	is_active = false
	ui_node.visible = false
	canvas_layer.visible = false
	highlight_sprite.visible = false
	vertical_line_2d.visible = false
	panel_line_2d.visible = false
	planet_info_panel.visible = false
	#zoom out the star and planets
	var startween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if current_planet_index >= 0:
		#we have a planet selected - lets shrink the star to zero 
		startween.tween_property(star, "scale", Vector3(0.01, 0.01, 0.01), 0.2)
	else:#otherwise - we shrink to normal scale
		startween.tween_property(star, "scale", Vector3(1, 1, 1), 0.5)
	startween.connect("finished", func(): active_tweens.erase(startween))
	active_tweens.append(startween)
	for i in range(planets.size()):
		var planet = planets[i]
		if current_planet_index >= 0:
			if planet == planets[current_planet_index]: 
				#if we get here - we know that we've selected a planet, not canceling back to starmap
				#lets scale up the planet - we're about to zoom into.
				var planettween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				active_tweens.append(planettween)
				planettween.tween_property(planet, "scale", Vector3(4, 4, 4), 0.5)
				planettween.connect("finished", func(): active_tweens.erase(planettween))
			else:
				var planettween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				active_tweens.append(planettween)
				# Start parallel tweens
				planettween.parallel().tween_property(planet, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
				var direction = Vector3(1, 0, 0)
				if i < current_planet_index:
					direction *= -1
				planettween.parallel().tween_property(planet, "position", planet.position + Vector3(10, 0, 0) * direction, 0.25)
				planettween.connect("finished", func(): active_tweens.erase(planettween))
	#now wait for the animations to complete - before we turn everything off
	await get_tree().create_timer(1).timeout
	
	for tween in active_tweens:
		tween.kill()
	active_tweens.clear()
	if current_planet_index < 0:
		for planet in planets:   #now discard the planets - we don't need them now
			planet.queue_free()
		planets = []
		hide()
	set_process(false)
	pass

func _input(event):
	if not is_active:
		return
	if event.is_action_pressed("navigate_left"):
		select_planet((current_planet_index - 1 + planets.size()) % planets.size())
	elif event.is_action_pressed("navigate_right"):
		select_planet((current_planet_index + 1) % planets.size())
	elif event.is_action_pressed("select"):
		emit_signal("planet_selected", planets[current_planet_index])

func select_planet(index: int):
	print("select_planet")
	if index < 0 or index >= planets.size():
		return
	current_planet_index = index
	var planet = planets[index]
	highlight_sprite.global_transform.origin = planet.global_transform.origin + Vector3(0, 0.5, 0)
	highlight_sprite.visible = true
	update_info_panel(planet)
	animate_lines(planet.global_transform.origin + Vector3(0, 0.25, 0))

func update_info_panel(planet):
	# Assuming planet scenes have a resource or properties; adjust based on actual planet structure
	var planet_name = planet.name  # Fallback to node name if no resource
	var difficulty = 1  # Default; replace with actual data if available
	var planet_type = "Rocky"  # Default; replace with actual data
	var locked = false  # Default; replace with actual data
	
	# If planets have a resource or metadata, access it here (e.g., planet.planet_resource)
	# For now, using placeholders based on GDD and existing structure
	planet_name_label.text = "Planet: %s" % planet_name
	difficulty_label.text = "Difficulty: %d" % difficulty
	type_label.text = "Type: %s" % planet_type
	locked_label.text = "Locked: %s" % ("Yes" if locked else "No")
	planet_info_panel.visible = true

func animate_lines(start_pos: Vector3):
	var screen_pos = star_menu.camera.unproject_position(start_pos)
	var screen_end_pos = screen_pos + Vector2(0, -100)  # Draw line up 100 pixels
	var panel_screen_pos = planet_info_panel.get_global_rect().position  # Top-left corner of panel
	
	vertical_line_2d.points = [screen_pos, screen_pos]
	panel_line_2d.points = [screen_end_pos, screen_end_pos]
	vertical_line_2d.visible = true
	panel_line_2d.visible = false
	
	var tween = create_tween()
	tween.tween_method(
		func(t):
			var end = screen_pos.lerp(screen_end_pos, t)
			vertical_line_2d.points = [screen_pos, end], 0.0, 1.0, 0.10 
	)
	tween.tween_callback(func(): panel_line_2d.visible = true)
	tween.tween_method(
		func(t):
			var end = screen_end_pos.lerp(panel_screen_pos, t)
			panel_line_2d.points = [screen_end_pos, end], 0.0, 1.0, 0.15
	)
	tween.tween_callback(func(): planet_info_panel.visible = true)
	active_tweens.append(tween)
	tween.connect("finished", func(): active_tweens.erase(tween))
