extends Node3D

@onready var camera = $Camera3D
@onready var back_button = $UI/BackButton
var systems = {
	"Alpha": {"difficulty": "Easy", "planets": ["alpha_one", "alpha_two", "alpha_three"], "unlocked": true},
	"Beta": {"difficulty": "Medium", "planets": ["beta_one", "beta_two"], "unlocked": false}
}
var planet_scenes = {
	"alpha_one": preload("res://scenes/planets/alpha_one.tscn"),
	"alpha_two": preload("res://scenes/planets/alpha_two.tscn"),
	"alpha_three": preload("res://scenes/planets/alpha_three.tscn"),
	"beta_one": preload("res://scenes/planets/beta_one.tscn"),
	"beta_two": preload("res://scenes/planets/beta_two.tscn")
}
var completed_planets = []
var selected_system = null
var initial_camera_pos = Vector3(0, 0, 64)
var target_zoom = Vector3(0, 0, 64)
var transition_duration = 0.5
var transition_timer = 0.0
var is_zoomed = false
var is_zooming_out = false

func _ready():
	$Alpha.input_event.connect(_on_system_input.bind("Alpha"))
	$Beta.input_event.connect(_on_system_input.bind("Beta"))
	$Beta.visible = systems["Alpha"]["planets"].all(func(p): return completed_planets.has(p))
	camera.global_position = initial_camera_pos
	camera.rotation = Vector3(0, 0, 0)
	target_zoom = initial_camera_pos
	back_button.visible = false
	back_button.pressed.connect(_on_back_pressed)
	var alpha_mesh = $Alpha.get_node_or_null("Mesh")
	var beta_mesh = $Beta.get_node_or_null("Mesh")
	if alpha_mesh and alpha_mesh.material_override:
		alpha_mesh.material_override.set_shader_parameter("opacity", 1.0)
		print("Alpha opacity set to 1.0")
	else:
		print("Alpha Mesh or material_override null: ", alpha_mesh, " ", alpha_mesh.material_override if alpha_mesh else "N/A")
	if beta_mesh and beta_mesh.material_override:
		beta_mesh.material_override.set_shader_parameter("opacity", 1.0)
		print("Beta opacity set to 1.0")
	else:
		print("Beta Mesh or material_override null: ", beta_mesh, " ", beta_mesh.material_override if beta_mesh else "N/A")
	print("Camera start: ", camera.global_position, " Rotation: ", camera.rotation)

func _process(delta):
	if selected_system and transition_timer < transition_duration:
		transition_timer += delta
		var t = transition_timer / transition_duration
		var system_node = get_node(selected_system)
		var mesh = system_node.get_node_or_null("Mesh")
		if is_zoomed and not is_zooming_out:
			camera.global_position = initial_camera_pos.lerp(target_zoom, t)
			if mesh and mesh.material_override:
				mesh.material_override.set_shader_parameter("opacity", 1.0 - t)
				print("Zoom in ", selected_system, " T: ", t, " Opacity: ", 1.0 - t)
			for planet in $Planets.get_children():
				planet.scale = Vector3.ZERO.lerp(Vector3.ONE, t)
				print("Planet ", planet.name, " scale: ", planet.scale)
			if t >= 1.0:
				system_node.visible = false
				system_node.collision_layer = 0
				print(selected_system, " zoomed in and hidden")
		elif is_zooming_out:
			camera.global_position = target_zoom.lerp(initial_camera_pos, t)
			if mesh and mesh.material_override:
				mesh.material_override.set_shader_parameter("opacity", t)
				print("Zoom out ", selected_system, " T: ", t, " Opacity: ", t)
			for planet in $Planets.get_children():
				planet.scale = Vector3.ONE.lerp(Vector3.ZERO, t)
				print("Planet ", planet.name, " scale: ", planet.scale)
			if t >= 1.0:
				for planet in $Planets.get_children():
					planet.queue_free()
				is_zoomed = false
				is_zooming_out = false
				back_button.visible = false
				selected_system = null
				print(system_node.name, " zoomed out and restored")

func _on_system_input(_viewport, event, _shape_idx, _owner, _self, system_name):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not systems[system_name]["unlocked"]:
			print(system_name, " locked—complete previous system!")
			return
		selected_system = system_name
		zoom_to_system()
		print("Zooming to: ", target_zoom)

func zoom_to_system():
	var system_node = get_node(selected_system)
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
	var system_pos = get_node(selected_system).global_position
	var current_offset = 0.0
	for i in system["planets"].size():
		var planet_name = system["planets"][i]
		var planet = planet_scenes[planet_name].instantiate()
		planet.name = planet_name
		var collision = planet.get_node("CollisionShape3D")
		var radius = collision.shape.radius if collision and collision.shape is SphereShape3D else 0.5
		current_offset += radius
		planet.position = system_pos + Vector3(current_offset, 0, 0)
		current_offset += radius + 0.5
		planet.scale = Vector3.ZERO  # Start at zero scale
		$Planets.add_child(planet)
		planet.input_event.connect(_on_planet_input.bind(planet_name))
		print("Spawned: ", planet_name, " at ", planet.position, " Radius: ", radius)
	back_button.visible = true

func _on_planet_input(_viewport, event, _shape_idx, _owner, _self, planet_name):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Selected planet: ", planet_name)
		get_tree().change_scene_to_file("res://scenes/perk_selection.tscn")

func _on_back_pressed():
	var system_node = get_node(selected_system)
	system_node.visible = true
	system_node.collision_layer = 1
	is_zoomed = false
	is_zooming_out = true
	transition_timer = 0.0

func complete_planet(planet_name):
	if not completed_planets.has(planet_name):
		completed_planets.append(planet_name)
		print("Completed: ", planet_name)
		$Beta.visible = systems["Alpha"]["planets"].all(func(p): return completed_planets.has(p))
		
