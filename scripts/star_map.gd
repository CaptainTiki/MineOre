extends Node3D

@onready var camera = $Camera3D
@onready var back_button = $UI/BackButton
@onready var alpha_popup = $UI/AlphaPopup
@onready var alpha_label = $UI/AlphaPopup/AlphaInfo/AlphaLabel
@onready var beta_popup = $UI/BetaPopup
@onready var beta_label = $UI/BetaPopup/BetaInfo/BetaLabel
@onready var planet_tooltip = $UI/PlanetTooltip
@onready var tooltip_label = $UI/PlanetTooltip/TooltipLabel
@onready var systems_node = $Systems

var systems = {}
var selected_system = null
var initial_camera_pos = Vector3(0, 0, 64)
var target_zoom = Vector3(0, 0, 64)
var transition_duration = 0.5
var transition_timer = 0.0
var is_zoomed = false
var is_zooming_out = false

func _ready():
	get_tree().paused = false
	# Use existing systems in the scene tree
	for system in systems_node.get_children():
		var data = system.get_system_data()
		systems[data["name"]] = data
		system.input_event.connect(_on_system_input.bind(data["name"]))
		system.mouse_entered.connect(_on_system_hover.bind(data["name"], true))
		system.mouse_exited.connect(_on_system_hover.bind(data["name"], false))
		# Keep all systems visible, no points-based hiding
	
	camera.global_position = initial_camera_pos
	camera.rotation = Vector3(0, 0, 0)
	target_zoom = initial_camera_pos
	back_button.visible = false
	back_button.pressed.connect(_on_back_pressed)
	for system_name in systems:
		update_system_ui(system_name)
	planet_tooltip.visible = false
	print("Camera start: ", camera.global_position, " Rotation: ", camera.rotation)
	print("Paused: ", get_tree().paused)
	print("Points: ", GameState.get_points())
	print("Loaded systems: ", systems.keys())

func _process(delta):
	if selected_system and transition_timer < transition_duration:
		transition_timer += delta
		var t = transition_timer / transition_duration
		var system_node = systems_node.get_node(selected_system)
		var mesh = system_node.get_node_or_null("Mesh")
		if is_zoomed and not is_zooming_out:
			camera.global_position = initial_camera_pos.lerp(target_zoom, t)
			if mesh and mesh.material_override:
				mesh.material_override.set_shader_parameter("opacity", 1.0 - t)
			for planet in $Planets.get_children():
				planet.scale = Vector3.ZERO.lerp(Vector3.ONE, t)
			if t >= 1.0:
				system_node.visible = false
				system_node.collision_layer = 0
		elif is_zooming_out:
			camera.global_position = target_zoom.lerp(initial_camera_pos, t)
			if mesh and mesh.material_override:
				mesh.material_override.set_shader_parameter("opacity", t)
			for planet in $Planets.get_children():
				planet.scale = Vector3.ONE.lerp(Vector3.ZERO, t)
			if t >= 1.0:
				for planet in $Planets.get_children():
					planet.queue_free()
				is_zoomed = false
				is_zooming_out = false
				back_button.visible = false
				selected_system = null
	
	# Planet selection
	if is_zoomed and Input.is_action_just_pressed("action"):
		var planets = $Planets.get_children()
		for planet in planets:
			if planet.get_meta("hovered", false):
				var data = planet.get_planet_data()
				if GameState.get_points() < data["points_required"]:
					print(data["name"], " locked—need ", data["points_required"], " points!")
				else:
					print("Selected planet: ", data["name"])
					var level = load(data["level_path"]).instantiate()
					get_tree().root.add_child(level)
					level.assign_planet(data["name"])
					get_tree().current_scene.queue_free()
					get_tree().current_scene = level
				break
	
	if planet_tooltip.visible:
		var hovered = $Planets.get_children().filter(func(p): return p.get_meta("hovered", false))
		if hovered.size() > 0:
			update_planet_tooltip_position(hovered[0])

func _on_system_input(_viewport, event, _shape_idx, _owner, _self, system_name):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if GameState.get_points() < systems[system_name]["points_required"]:
			print(system_name, " locked—need ", systems[system_name]["points_required"], " points!")
			return
		selected_system = system_name
		zoom_to_system()

func _on_system_hover(system_name, entered):
	var popup = alpha_popup if system_name == "Alpha" else beta_popup
	if entered and not is_zoomed:
		update_system_ui(system_name)
		var system_node = systems_node.get_node(system_name)
		var screen_pos = camera.unproject_position(system_node.global_position + Vector3(0, 2, 0))
		var popup_size = popup.size
		popup.position = screen_pos - Vector2(popup_size.x / 2, popup_size.y + 25)
		popup.popup()
		print("Hover ", system_name, " - Popup visible: ", popup.visible)
	else:
		popup.hide()

func update_system_ui(system_name):
	var system = systems[system_name]
	var label = alpha_label if system_name == "Alpha" else beta_label
	var completed = system["planets"].filter(func(p): return GameState.is_planet_completed(p.instantiate().get_planet_data()["name"])).size()
	var total = system["planets"].size()
	var text = "%s\nDifficulty: %s\nProgress: %d/%d" % [system_name, system["difficulty"], completed, total]
	if GameState.get_points() < system["points_required"]:
		text += "\nLocked (Need %d points)" % system["points_required"]
	label.text = text
	print("UI updated for ", system_name, ": ", text)

func zoom_to_system():
	var system_node = systems_node.get_node(selected_system)
	var system_pos = system_node.global_position
	target_zoom = system_pos + (camera.global_position - system_pos).normalized() * 15 + Vector3(0, 5, 0)
	is_zoomed = true
	is_zooming_out = false
	transition_timer = 0.0
	back_button.visible = true
	spawn_planets()

func spawn_planets():
	for planet in $Planets.get_children():
		planet.queue_free()
	var system = systems[selected_system]
	var system_pos = systems_node.get_node(selected_system).global_position
	var current_offset = 0.0
	for planet_scene in system["planets"]:
		var planet = planet_scene.instantiate()
		var collision = planet.get_node("CollisionShape3D")
		var radius = collision.shape.radius if collision and collision.shape is SphereShape3D else 0.5
		current_offset += radius
		planet.position = system_pos + Vector3(current_offset, 0, 0)
		current_offset += radius + 0.5
		planet.scale = Vector3.ZERO
		$Planets.add_child(planet)
		planet.mouse_entered.connect(_on_planet_hover.bind(planet.get_planet_data()["name"], true))
		planet.mouse_exited.connect(_on_planet_hover.bind(planet.get_planet_data()["name"], false))
		planet.set_meta("hovered", false)
	back_button.visible = true

func _on_planet_hover(planet_name, entered):
	if is_zoomed:
		if entered:
			var planet = $Planets.get_children().filter(func(p): return p.get_planet_data()["name"] == planet_name)[0]
			planet.set_meta("hovered", true)
			tooltip_label.text = planet_name
			var points_needed = planet.get_planet_data()["points_required"]
			if GameState.get_points() < points_needed:
				tooltip_label.text += "\nLocked (Need %d points)" % points_needed
			planet_tooltip.visible = true
			update_planet_tooltip_position(planet)
			print("Planet hover: ", planet_name, " - Tooltip visible: ", planet_tooltip.visible)
		else:
			var planet = $Planets.get_children().filter(func(p): return p.get_planet_data()["name"] == planet_name)[0]
			planet.set_meta("hovered", false)
			planet_tooltip.visible = false

func update_planet_tooltip_position(planet):
	var screen_pos = camera.unproject_position(planet.global_position + Vector3(0, 1, 0))
	var tooltip_size = planet_tooltip.size
	planet_tooltip.position = screen_pos - Vector2(tooltip_size.x / 2, tooltip_size.y + 25)

func _on_back_pressed():
	var system_node = systems_node.get_node(selected_system)
	system_node.visible = true
	system_node.collision_layer = 1
	is_zoomed = false
	is_zooming_out = true
	transition_timer = 0.0

func complete_planet(planet_name):
	GameState.complete_planet(planet_name)
	for system_name in systems:
		# No visibility toggle here
		update_system_ui(system_name)
