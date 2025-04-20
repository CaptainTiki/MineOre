extends Node3D

# State enum for managing UI and scene states
enum State {
	STAR_MAP,
	SYSTEM_VIEW,
	PLANET_VIEW,
	PERKS_VIEW
}
var current_state = State.STAR_MAP

# Node references
@onready var systems_node = $Systems
@onready var camera = $Camera3D
@onready var star_map_ui = $UI/StarMapUI
@onready var info_panel = $UI/StarMapUI/InfoPanel
@onready var info_label = $UI/StarMapUI/InfoPanel/Label  # Assuming a Label node exists
@onready var line_drawer = $UI/StarMapUI/LineDrawer      # Assuming a Line2D node exists
@onready var perks_screen = $UI/PerksScreen
@onready var planet_view_ui = $UI/PlanetViewUI
@onready var planet_name_label = $UI/PlanetViewUI/Panel/VBoxContainer/PlanetNameLabel
@onready var planet_stats_label = $UI/PlanetViewUI/Panel/VBoxContainer/PlanetStatsLabel
@onready var drop_button = $UI/PlanetViewUI/Panel/VBoxContainer/DropButton
@onready var back_button = $UI/PlanetViewUI/Panel/VBoxContainer/BackButton

# State variables
var selected_system_node = null
var selected_planet_node = null
var selected_planet_data = null
var target_camera_pos = Vector3.ZERO
var initial_camera_pos = Vector3(0, 10, 20)  # Adjust based on your scene
var transition_timer = 0.0
var transition_duration = 1.0  # Seconds for camera movement

func _ready():
	# Set initial camera position
	camera.global_position = initial_camera_pos
	target_camera_pos = initial_camera_pos
	
	# Hide UI elements that start hidden
	planet_view_ui.visible = false
	perks_screen.visible = false
	
	# Connect button signals
	drop_button.pressed.connect(_on_drop_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Connect signals from system nodes (assuming each system emits system_selected)
	for system in systems_node.get_children():
		system.connect("system_selected", _on_system_selected)
		system.connect("planet_selected", _on_planet_selected)

func _process(delta):
	# Smoothly move camera to target position
	if transition_timer < transition_duration:
		transition_timer += delta
		var t = min(transition_timer / transition_duration, 1.0)
		camera.global_position = camera.global_position.lerp(target_camera_pos, t)
	
	# Update LineDrawer
	update_line_drawer()

func _input(event):
	match current_state:
		State.STAR_MAP:
			# Navigate systems with input (simplified example)
			if event.is_action_pressed("navigate_right"):
				select_next_system()
		State.SYSTEM_VIEW:
			# Navigate planets via the selected system (handled in system.gd)
			pass
		State.PLANET_VIEW:
			# Input handled by UI buttons
			pass
		State.PERKS_VIEW:
			# Input handled by PerksScreen
			pass

# State transition function
func set_state(new_state):
	# Cleanup previous state
	match current_state:
		State.PLANET_VIEW:
			if selected_planet_node:
				selected_planet_node.scale = Vector3(1, 1, 1)  # Reset scale
			if selected_system_node:
				for planet in selected_system_node.planets_node.get_children():
					planet.visible = true  # Show all planets again
	
	current_state = new_state
	
	# Setup new state
	match new_state:
		State.STAR_MAP:
			target_camera_pos = initial_camera_pos
			for system in systems_node.get_children():
				system.mesh.visible = true
				for planet in system.planets_node.get_children():
					planet.visible = false
			star_map_ui.visible = true
			planet_view_ui.visible = false
			perks_screen.visible = false
			update_info_panel()
		
		State.SYSTEM_VIEW:
			target_camera_pos = selected_system_node.global_position + Vector3(0, 5, 15)
			selected_system_node.start_zoom_in()  # Show planets, hide system mesh
			for system in systems_node.get_children():
				if system != selected_system_node:
					system.mesh.visible = false
			star_map_ui.visible = true
			planet_view_ui.visible = false
			perks_screen.visible = false
			update_info_panel()
		
		State.PLANET_VIEW:
			target_camera_pos = selected_planet_node.global_position + Vector3(0, 2, 5)
			selected_planet_node.scale = Vector3(2, 2, 2)  # Scale up selected planet
			for planet in selected_system_node.planets_node.get_children():
				if planet != selected_planet_node:
					planet.visible = false
			star_map_ui.visible = false
			planet_view_ui.visible = true
			perks_screen.visible = false
			planet_name_label.text = selected_planet_data["name"]
			planet_stats_label.text = "Record Time: N/A\nRecord Points: N/A\nTimes Played: 0"
			if selected_planet_data.get("locked", false):
				planet_stats_label.text += "\nLocked (Need %d points)" % selected_planet_data.get("points_required", 0)
				drop_button.disabled = true
			else:
				drop_button.disabled = false
		
		State.PERKS_VIEW:
			star_map_ui.visible = false
			planet_view_ui.visible = false
			perks_screen.visible = true
			perks_screen.show_perks(selected_planet_data)
	
	transition_timer = 0.0  # Reset for camera animation

# Signal handlers
func _on_system_selected(system_node):
	selected_system_node = system_node
	set_state(State.SYSTEM_VIEW)

func _on_planet_selected(planet_node, planet_data):
	selected_planet_node = planet_node
	selected_planet_data = planet_data
	set_state(State.PLANET_VIEW)

func _on_drop_pressed():
	if current_state == State.PLANET_VIEW and not selected_planet_data.get("locked", false):
		set_state(State.PERKS_VIEW)

func _on_back_pressed():
	if current_state == State.PLANET_VIEW:
		set_state(State.SYSTEM_VIEW)

# Helper functions
func update_info_panel():
	if current_state == State.STAR_MAP and selected_system_node:
		var system_data = selected_system_node.get_system_data()
		info_label.text = "%s\nDifficulty: %s" % [system_data["name"], system_data["difficulty"]]
	elif current_state == State.SYSTEM_VIEW and selected_system_node:
		var planet_data = selected_system_node.get_selected_planet_data()
		info_label.text = "%s\nType: %s" % [planet_data["name"], planet_data["type"]]

func update_line_drawer():
	if current_state == State.STAR_MAP and selected_system_node:
		line_drawer.start_pos = camera.unproject_position(selected_system_node.global_position)
	elif current_state == State.SYSTEM_VIEW and selected_system_node:
		var planet_node = selected_system_node.planets_node.get_child(selected_system_node.current_planet_index)
		line_drawer.start_pos = camera.unproject_position(planet_node.global_position)
	line_drawer.end_pos = info_panel.position + info_panel.size / 2

func select_next_system():
	var systems = systems_node.get_children()
	if systems.size() == 0:
		return
	var current_idx = systems.find(selected_system_node) if selected_system_node else -1
	var next_idx = (current_idx + 1) % systems.size()
	selected_system_node = systems[next_idx]
	update_info_panel()
	update_line_drawer()
