extends Node3D
class_name StarMenu

enum ViewState { STAR_MAP, SYSTEM, PLANET, PERKS }

var current_state = ViewState.STAR_MAP
var current_planet: Node3D = null
var current_system_node: Star_System
var is_camera_moving = false
var active_tweens: Array[Tween] = []

@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D

@onready var star_map_view = $StarMapView
@onready var system_view = $SystemView
@onready var planet_view = $PlanetView
@onready var perks_view = $PerksView
@onready var planets_node = $Planets
@onready var camera = $Camera3D

func _ready():
	star_map_view.connect("system_selected", _on_system_selected)
	system_view.connect("planet_selected", _on_planet_selected)
	planet_view.connect("planet_confirm", _on_planet_confirm)
	perks_view.connect("load_level_selected", _on_load_level_selected)
	
	star_map_view.set_systems($StarSystems)
	transition_to(ViewState.STAR_MAP)

func _input(event):
	if event.is_action_pressed("cancel"):
		print("cancel pressed")
		on_cancel_pressed()

func _on_system_selected(system_node: Star_System):
	current_system_node = system_node
	transition_to(ViewState.SYSTEM)

func _on_planet_selected(planet: Node3D):
	current_planet = planet
	transition_to(ViewState.PLANET)

func _on_planet_confirm():
	transition_to(ViewState.PERKS)

func _on_load_level_selected():
	print("on load level selected")
	var fade_rect = $FadeRect/ColorRect
	LevelManager.level_path = current_planet.level_path
	get_tree().change_scene_to_file("res://menus/loading_menu.tscn")

func on_cancel_pressed():
	match current_state:
		ViewState.SYSTEM:
			system_view.current_planet_index = -1
			transition_to(ViewState.STAR_MAP)
		ViewState.PLANET:
			planet_view.disable_view()
			transition_to(ViewState.SYSTEM)
		ViewState.PERKS:
			perks_view.disable_view()
			transition_to(ViewState.PLANET)
		ViewState.STAR_MAP:
			get_tree().change_scene_to_file("res://menus/main_menu.tscn")
			pass

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
	system_view.disable_view()
	stop_all_animations(system_view)
	for system in $StarSystems.get_children():
		system.show()
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tweens.append(tween)
	is_camera_moving = true
	tween.tween_property(camera, "position", Vector3(0, 0, 350), 0.5)
	tween.connect("finished", func(): active_tweens.erase(tween))
	await tween.finished
	is_camera_moving = false

func transition_to_system() -> void:
	stop_all_animations(star_map_view)
	system_view.set_system(current_system_node)
	star_map_view.disable_view()
	system_view.enable_view()
	var star_position = current_system_node.global_position
	var camera_target_position = get_camera_position_for_zoom(star_position, 15.0, camera)
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tweens.append(tween)
	is_camera_moving = true
	tween.tween_property(camera, "position", camera_target_position, 0.5)
	tween.connect("finished", func(): active_tweens.erase(tween))
	await tween.finished
	is_camera_moving = false
	if system_view.planets.size() > 0:
		system_view.select_planet(0)
	
func transition_to_planet() -> void:
	system_view.disable_view()
	planet_view.enable_view()
	perks_view.hide()
	var planet_pos = current_planet.global_transform.origin
	var target_position = get_camera_position_for_zoom(planet_pos, 5, camera)
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tweens.append(tween)
	is_camera_moving = true
	tween.tween_property(camera, "global_transform:origin", target_position, 0.5)
	tween.connect("finished", func(): 
		active_tweens.erase(tween)
		if current_planet:
			current_planet.visible = true
		planet_view.set_planet(current_planet)
	)
	await tween.finished
	is_camera_moving = false

func transition_to_perks() -> void:
	planet_view.disable_view()
	perks_view.enable_view()
	perks_view.set_planet(current_planet)

func get_camera_position_for_zoom(star_position: Vector3, z_distance: float, level_camera: Camera3D) -> Vector3:
	var viewport = get_viewport()
	var aspect = float(viewport.size.x) / viewport.size.y
	var fov_rad = deg_to_rad(level_camera.fov)
	var tan_half_fov = tan(fov_rad / 2.0)
	var offset_x = z_distance * aspect * tan_half_fov
	var offset = Vector3(offset_x, 0, z_distance)
	return star_position + offset

func _on_camera_tween_completed():
	is_camera_moving = false

func stop_all_animations(node: Node):
	if node is AnimationPlayer:
		node.stop()
		node.play("RESET")
	for child in node.get_children():
		stop_all_animations(child)
