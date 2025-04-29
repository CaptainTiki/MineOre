#system_view.gd
extends Node3D
class_name SystemView

signal planet_selected

var current_system: Star_System
var star = null
var highlight_sprite: Sprite3D = null
var current_planet_index: int = 1
var current_planet: Planet
var planets: Array = []

var active_tweens: Array[Tween] = []
var is_active : bool = false

@onready var planet_info_panel = $UI/PlanetInfoPanel
@onready var planet_name_label = $UI/PlanetInfoPanel/InfoContainer/PlanetNameLabel
@onready var difficulty_label = $UI/PlanetInfoPanel/InfoContainer/DifficultyLabel
@onready var description_label: Label = $UI/PlanetInfoPanel/InfoContainer/DescriptionLabel
@onready var points_required_label: Label = $UI/PlanetInfoPanel/InfoContainer/PointsRequiredLabel
@onready var type_label = $UI/PlanetInfoPanel/InfoContainer/TypeLabel
@onready var locked_label = $UI/PlanetInfoPanel/InfoContainer/LockedLabel
@onready var ui_node: Control = $UI
@onready var planets_node: Node3D = $"../Planets"
@onready var star_menu: StarMenu = $".."

var canvas_layer: CanvasLayer
var vertical_line_2d: Line2D
var panel_line_2d: Line2D

func _ready():
	highlight_sprite = Sprite3D.new()
	highlight_sprite.texture = preload("res://assets/ring.png")
	highlight_sprite.scale = Vector3(1.0, 1.0, 1.0)
	highlight_sprite.translate(Vector3(0, 0.5, 0))
	highlight_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	highlight_sprite.visible = false
	add_child(highlight_sprite)
	
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	vertical_line_2d = Line2D.new()
	vertical_line_2d.width = 2
	vertical_line_2d.default_color = Color(1, 0, 0)
	vertical_line_2d.visible = false
	canvas_layer.add_child(vertical_line_2d)
	
	panel_line_2d = Line2D.new()
	panel_line_2d.width = 2
	panel_line_2d.default_color = Color(1, 0, 0)
	panel_line_2d.visible = false
	canvas_layer.add_child(panel_line_2d)
	
	planet_info_panel.position = Vector2(get_viewport().size.x - 320, 20)
	planet_info_panel.visible = false

func set_system(system: Star_System):
	current_system = system
	star = current_system.star
	var planet_position = Vector3(15, 0, 0) + system.global_position
	var startween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	startween.tween_property(star, "scale", Vector3(5, 5, 5), 0.5)
	active_tweens.append(startween)
	startween.connect("finished", func(): 
		active_tweens.erase(startween)
	)
	if planets.size() <= 0:
		for planet_scene in current_system.system_resource.planets:
			var planet = planet_scene.instantiate()
			planet.global_position = planet_position
			planet.scale = Vector3(0.01, 0.01, 0.01)
			if planets_node:
				planets_node.add_child(planet)
			else:
				add_child(planet)
			planets.append(planet)
			var planet_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			active_tweens.append(planet_tween)
			planet_tween.tween_property(planet, "scale", Vector3(1, 1, 1), 0.5)
			planet_tween.connect("finished", func(): 
				active_tweens.erase(planet_tween)
			)
			planet_position += Vector3(8, 0, 0)

func enable_view() -> void:
	global_position = current_system.global_position
	canvas_layer.visible = true
	self.show()
	self.set_process(true)
	ui_node.visible = true
	is_active = true
	for planet in planets:
		if is_instance_valid(planet):
			planet.visible = true
			planet.scale = Vector3(1, 1, 1)  # Reset scale to ensure visibility

func disable_view() -> void:
	is_active = false
	ui_node.visible = false
	canvas_layer.visible = false
	highlight_sprite.visible = false
	vertical_line_2d.visible = false
	panel_line_2d.visible = false
	planet_info_panel.visible = false
	
	# Clear any existing tweens
	for tween in active_tweens:
		tween.kill()
	active_tweens.clear()
	
	# Create new tweens
	if star:
		var startween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if current_planet_index >= 0:
			startween.tween_property(star, "scale", Vector3(0.01, 0.01, 0.01), 0.2)
		else:
			startween.tween_property(star, "scale", Vector3(1, 1, 1), 0.5)
		active_tweens.append(startween)
		startween.connect("finished", func(): 
			active_tweens.erase(startween)
		)
	
	for i in range(planets.size()):
		var planet = planets[i]
		if not is_instance_valid(planet):
			continue
		var planettween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		active_tweens.append(planettween)
		if current_planet_index >= 0 and planet == planets[current_planet_index]:
			planettween.tween_property(planet, "scale", Vector3(4, 4, 4), 0.5)
			planettween.tween_callback(func(): 
				if is_instance_valid(planet):
					planet.visible = true
			)
		else:
			planettween.parallel().tween_property(planet, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
			var direction = Vector3(1, 0, 0)
			if i < current_planet_index:
				direction *= -1
			planettween.parallel().tween_property(planet, "global_position", planet.global_position + Vector3(10, 0, 0) * direction, 0.25)
			planettween.tween_callback(func(): 
				if is_instance_valid(planet):
					planet.visible = false
			)
		planettween.connect("finished", func(): 
			active_tweens.erase(planettween)
		)
	
	# Wait for tweens with a timeout
	var timeout = 2.0  # Max 2 seconds
	var elapsed = 0.0
	while active_tweens.size() > 0 and elapsed < timeout:
		var tween = active_tweens[0]
		if tween.is_valid():
			await tween.finished
		else:
			active_tweens.erase(tween)
		elapsed += get_process_delta_time()
	
	if active_tweens.size() > 0:
		for tween in active_tweens:
			tween.kill()
	active_tweens.clear()
	
	if current_planet_index < 0:
		for planet in planets:
			if is_instance_valid(planet):
				planet.queue_free()
		planets = []
		hide()
	set_process(false)

func _input(event):
	if not is_active:
		return
	if event.is_action_pressed("navigate_left"):
		select_planet((current_planet_index - 1 + planets.size()) % planets.size())
	elif event.is_action_pressed("navigate_right"):
		select_planet((current_planet_index + 1) % planets.size())
	elif event.is_action_pressed("select"):
		if current_planet:
			var data = current_planet.get_planet_data()
			if data["points_required"] <= GameState.planet_completion_points:
				emit_signal("planet_selected", planets[current_planet_index])

func select_planet(index: int):
	if index < 0 or index >= planets.size():
		return
	current_planet_index = index
	var planet = planets[index]
	highlight_sprite.global_transform.origin = planet.global_transform.origin + Vector3(0, 0.5, 0)
	highlight_sprite.visible = true
	update_info_panel(planet)
	animate_lines(planet.global_transform.origin + Vector3(0, 0.25, 0))
	current_planet = planets[current_planet_index]
	print(current_planet.planet_name)

func update_info_panel(planet):
	if not planet or not planet.has_method("get_planet_data"):
		print("Error: Invalid planet or missing get_planet_data: ", planet)
		planet_name_label.text = "Planet: Unknown"
		difficulty_label.text = "Difficulty: -"
		type_label.text = "Type: -"
		locked_label.text = "Locked: -"
		planet_info_panel.visible = true
		return
	
	var data = planet.get_planet_data()
	if not data or not data is Dictionary:
		print("Error: Invalid planet data: ", data)
		planet_name_label.text = "Planet: Unknown"
		difficulty_label.text = "Difficulty: -"
		type_label.text = "Type: -"
		locked_label.text = "Locked: -"
		planet_info_panel.visible = true
		return
	
	# Fetch GameState for lock check
	var game_state = get_tree().root.get_node_or_null("GameState")
	var available_points = game_state.planet_completion_points if game_state else 0
	var locked = data.get("points_required", 0) > available_points
	
	# Update UI
	planet_name_label.text = "Planet: %s" % data.get("name", planet.name)
	difficulty_label.text = "Difficulty: %d" % data.get("difficulty", 1)
	type_label.text = "Type: %s" % data.get("type", "Rocky")
	locked_label.text = "Locked: %s" % ("Yes" if locked else "No")
	
	# Add points required and description (will need new labels in scene)
	if is_instance_valid(points_required_label):
		points_required_label.text = "Points Required: %d" % data.get("points_required", 0)
	if is_instance_valid(description_label):
		description_label.text = "Description: %s" % data.get("description", "No description available")
	
	planet_info_panel.visible = true
	print("Planet UI Updated: Name=%s, Locked=%s, Points Required=%d" % [data.get("name", planet.name), "Yes" if locked else "No", data.get("points_required", 0)])

func animate_lines(start_pos: Vector3):
	var screen_pos = star_menu.camera.unproject_position(start_pos)
	var screen_end_pos = screen_pos + Vector2(0, -100)
	var panel_screen_pos = planet_info_panel.get_global_rect().position
	
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
	tween.connect("finished", func(): 
		active_tweens.erase(tween)
	)
