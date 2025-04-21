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
var current_system_index = 0
var last_system_count = 0
var was_perks_active = false

func _ready():
	get_tree().paused = false
	update_systems()
	print("Initialized systems: ", systems.keys())
	print("Systems node children: ", systems_node.get_children())
	
	camera.global_position = initial_camera_pos
	camera.rotation = Vector3(0, 0, 0)
	target_zoom = initial_camera_pos
	back_button.visible = false
	back_button.pressed.connect(_on_back_pressed)
	planet_tooltip.visible = false
	perks_screen.visible = false
	perks_screen.perks_selected.connect(_on_perks_selected)
	perks_screen.perks_canceled.connect(_on_perks_canceled)
	
	back_button.focus_mode = Control.FOCUS_ALL
	current_system_index = 0
	update_system_highlight()

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
				current_system_index = 0
				update_system_highlight()
	
	var current_system_count = systems_node.get_child_count()
	if current_system_count != last_system_count:
		update_systems()
		last_system_count = current_system_count
		print("Updated systems: ", systems.keys())

func update_systems():
	systems.clear()
	for system in systems_node.get_children():
		var data = system.get_system_data()
		print("System node name: ", system.name, ", system_name: ", data["name"])
		if systems_node.get_node_or_null(data["name"]) != null:
			systems[data["name"]] = data
			system.initialize_ui(planet_tooltip, tooltip_label)
			system.input_event.connect(_on_system_input.bind(data["name"]))
			system.planet_selected.connect(_on_planet_selected)
		else:
			print("Error: System node '%s' not found in systems_node" % data["name"])

func _input(event):
	if is_zoomed:
		if Input.is_action_just_pressed("cancel") and not perks_screen.visible and not was_perks_active:
			_on_back_pressed()
	else:
		var system_names = systems.keys()
		if system_names.size() > 0:
			if Input.is_action_just_pressed("navigate_right"):
				current_system_index = (current_system_index + 1) % system_names.size()
				update_system_highlight()
			elif Input.is_action_just_pressed("navigate_left"):
				current_system_index = (current_system_index - 1) % system_names.size()
				if current_system_index < 0:
					current_system_index = system_names.size() - 1
				update_system_highlight()
			elif Input.is_action_just_pressed("select"):
				var system_name = system_names[current_system_index]
				if GameState.get_points() >= systems[system_name]["points_required"]:
					selected_system = system_name
					zoom_to_system()
		else:
			print("Warning: No systems available for navigation")

func update_system_highlight():
	var system_names = systems.keys()
	for i in system_names.size():
		var system_node = systems_node.get_node_or_null(system_names[i])
		if system_node == null:
			print("Error: System node '%s' not found in systems_node" % system_names[i])
			continue
		var is_selected = (i == current_system_index)
		if is_selected:
			system_node.update_system_ui()
			var screen_pos = get_viewport().get_camera_3d().unproject_position(system_node.global_position + Vector3(0, 2, 0))
			system_node.popup.position = screen_pos - Vector2(system_node.popup.size.x / 2, system_node.popup.size.y + 25)
			system_node.popup.show()
		else:
			system_node.popup.hide()
	if system_names.size() > 0:
		print("Highlighted system: ", system_names[current_system_index])

func _on_system_input(_viewport, event, _shape_idx, _owner, _self, system_name):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if GameState.get_points() < systems[system_name]["points_required"]:
			return
		selected_system = system_name
		zoom_to_system()

func _on_back_pressed():
	if selected_system:
		var system_node = systems_node.get_node(selected_system)
		system_node.monitoring = true
		system_node.monitorable = true
		system_node.start_zoom_out()
		is_zoomed = false
		is_zooming_out = true
		transition_timer = 0.0
		back_button.visible = false

func _on_perks_selected(perks, planet_data):
	var level = load(planet_data["level_path"]).instantiate()
	get_tree().root.add_child(level)
	level.assign_planet(planet_data["name"])
	get_tree().current_scene.queue_free()
	get_tree().current_scene = level

func _on_planet_selected(planet_data):
	if GameState.get_points() >= planet_data["points_required"]:
		planet_tooltip.visible = false
		if selected_system:
			var system_node = systems_node.get_node(selected_system)
			system_node.start_perks_mode()
		perks_screen.show_perks(planet_data)
		was_perks_active = true

func _on_perks_canceled():
	if selected_system:
		var system_node = systems_node.get_node(selected_system)
		system_node.end_perks_mode()
	# Delay resetting was_perks_active to prevent immediate zoom-out
	await get_tree().process_frame
	was_perks_active = false

func zoom_to_system():
	var system_node = systems_node.get_node(selected_system)
	var system_pos = system_node.global_position
	target_zoom = system_pos + (camera.global_position - system_pos).normalized() * 15 + Vector3(0, 5, 0)
	is_zoomed = true
	is_zooming_out = false
	transition_timer = 0.0
	back_button.visible = true
	back_button.grab_focus()
	system_node.start_zoom_in()
	planet_tooltip.visible = false
