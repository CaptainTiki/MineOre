extends Node3D

enum ViewState { STAR_MAP, SYSTEM, PLANET, PERKS }

var current_state = ViewState.STAR_MAP
var current_planet: Node3D = null
var current_system_node: Star_System

@onready var star_map_view = $StarMapView
@onready var system_view = $SystemView
@onready var planet_view = $PlanetView
@onready var perks_view = $PerksView
@onready var camera = $Camera3D

func _ready():
	star_map_view.connect("system_selected", _on_system_selected)
	#system_view.connect("planet_selected", _on_planet_selected)
	planet_view.connect("perks_selected", _on_perks_selected)
	planet_view.connect("level_selected", _on_level_selected)
	perks_view.connect("perks_confirmed", _on_perks_confirmed)
	
	# Pass StarSystems node to StarMapView
	star_map_view.set_systems($StarSystems)
	transition_to(ViewState.STAR_MAP)

func _input(event):
	if event.is_action_pressed("cancel"):
		on_cancel_pressed()

func _on_system_selected(system_node: Star_System):
	current_system_node = system_node
	transition_to(ViewState.SYSTEM)

func _on_planet_selected(planet: Node3D):
	current_planet = planet
	transition_to(ViewState.PLANET)

func _on_perks_selected():
	transition_to(ViewState.PERKS)

func _on_perks_confirmed():
	transition_to(ViewState.PLANET)

func _on_level_selected(level: PackedScene):
	get_tree().change_scene_to_packed(level)

func on_cancel_pressed():
	match current_state:
		ViewState.SYSTEM:
			await system_view.exit_view() # Wait for planets to scale down
			transition_to(ViewState.STAR_MAP)
		ViewState.PLANET:
			transition_to(ViewState.SYSTEM) # Add exit_view for planet_view later
		ViewState.PERKS:
			transition_to(ViewState.PLANET) # Add exit_view for perks_view later
		ViewState.STAR_MAP:
			pass # Optionally exit the menu

func transition_to(new_state: ViewState):
	current_state = new_state
	match new_state:
		ViewState.STAR_MAP:
			transition_to_starmap()
		ViewState.SYSTEM:
			transition_to_system()
		ViewState.PLANET:
			transition_to_planet()
		ViewState.PERKS:
			transition_to_perks()

func transition_to_starmap() -> void:
	star_map_view.enable_view()
	system_view.hide()
	for system in $StarSystems.get_children():
		system.show()
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position", Vector3(0, 0, 350), 0.5)


func transition_to_system() -> void:
	system_view.show()
	for system in $StarSystems.get_children():
		if system != current_system_node:
			system.hide()
	current_system_node.show()
	system_view.global_position = current_system_node.global_position
	system_view.set_system(current_system_node)
	star_map_view.disable_view()
	var star_position = current_system_node.global_position
	var camera_target_position = get_camera_position_for_zoom(star_position, 15.0, camera)
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position", camera_target_position, 0.5)
	
func transition_to_planet() -> void:
	star_map_view.hide()
	system_view.hide()
	planet_view.show()
	planet_view.set_planet(current_planet)
	perks_view.hide()
	camera.position = Vector3(0, 2, 5)
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)

func transition_to_perks() -> void:
	star_map_view.hide()
	system_view.hide()
	planet_view.hide()
	perks_view.show()
	perks_view.set_planet(current_planet)
	camera.position = Vector3(0, 2, 5)
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)

func get_camera_position_for_zoom(star_position: Vector3, z_distance: float, camera: Camera3D) -> Vector3:
	var viewport = get_viewport()
	var aspect = float(viewport.size.x) / viewport.size.y
	var fov_rad = deg_to_rad(camera.fov)
	var tan_half_fov = tan(fov_rad / 2.0)
	var offset_x = z_distance * aspect * tan_half_fov
	var offset = Vector3(offset_x, 0, z_distance)
	return star_position + offset
