extends Node3D

@onready var camera = $Camera3D
@onready var back_button = $UI/BackButton
@onready var planet_tooltip = $UI/PlanetTooltip
@onready var tooltip_label = $UI/PlanetTooltip/TooltipLabel
@onready var systems_node = $Systems
@onready var perks_screen : PerksScreen = $UI/PerksScreen

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
	for system in systems_node.get_children():
		var data = system.get_system_data()
		systems[data["name"]] = data
		system.initialize_ui(planet_tooltip, tooltip_label)
		system.input_event.connect(_on_system_input.bind(data["name"]))
		system.planet_selected.connect(_on_planet_selected)
	
	camera.global_position = initial_camera_pos
	camera.rotation = Vector3(0, 0, 0)
	target_zoom = initial_camera_pos
	back_button.visible = false
	back_button.pressed.connect(_on_back_pressed)
	planet_tooltip.visible = false
	perks_screen.visible = false
	perks_screen.perks_selected.connect(_on_perks_selected)

func _process(delta):
	if selected_system and transition_timer < transition_duration:
		transition_timer += delta
		var t = transition_timer / transition_duration
		var system_node = systems_node.get_node(selected_system)
		if is_zoomed and not is_zooming_out:
			camera.global_position = initial_camera_pos.lerp(target_zoom, t)
			if t >= 1.0:
				system_node.monitoring = false
				system_node.monitorable = false
		elif is_zooming_out:
			camera.global_position = target_zoom.lerp(initial_camera_pos, t)
			if t >= 1.0:
				is_zoomed = false
				is_zooming_out = false
				back_button.visible = false
				selected_system = null
				transition_timer = 0.0

func _on_system_input(_viewport, event, _shape_idx, _owner, _self, system_name):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if GameState.get_points() < systems[system_name]["points_required"]:
			return
		selected_system = system_name
		zoom_to_system()

func _on_back_pressed():
	var system_node = systems_node.get_node(selected_system)
	system_node.monitoring = true
	system_node.monitorable = true
	system_node.start_zoom_out()
	is_zoomed = false
	is_zooming_out = true
	transition_timer = 0.0

func _on_perks_selected(perks, planet_data):
	var level = load(planet_data["level_path"]).instantiate()
	get_tree().root.add_child(level)
	level.assign_planet(planet_data["name"])
	get_tree().current_scene.queue_free()
	get_tree().current_scene = level

func _on_planet_selected(planet_data):
	if GameState.get_points() >= planet_data["points_required"]:
		perks_screen.show_perks(planet_data)

func zoom_to_system():
	var system_node = systems_node.get_node(selected_system)
	var system_pos = system_node.global_position
	target_zoom = system_pos + (camera.global_position - system_pos).normalized() * 15 + Vector3(0, 5, 0)
	is_zoomed = true
	is_zooming_out = false
	transition_timer = 0.0
	back_button.visible = true
	system_node.start_zoom_in()
