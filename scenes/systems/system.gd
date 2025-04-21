extends Area3D
class_name StarSystem

signal planet_selected(planet_data)
signal spawn_complete

enum ZoomState { IDLE, ZOOMING_IN, ZOOMING_OUT }

@export var system_name: String = ""
@export var difficulty: String = ""
@export var points_required: int = 0
@export var planet_scenes: Array[PackedScene] = []
@export var star_scene: PackedScene
@export var target_zoom_distance: float = 15.0

@onready var planets_node = $Planets
@onready var star_node = $Star
@onready var mesh = $Mesh
@onready var collision_shape = $CollisionShape3D

var popup = null
var planet_tooltip = null
var tooltip_label = null
var zoom_state = ZoomState.IDLE
var transition_timer = 0.0
var transition_duration = 0.5
var is_perks_active = false
var current_planet_index = 0
var planets = []

func _ready():
	if not system_name or not planet_scenes:
		print("Error: System ", name, " missing required data!")
	if not planets_node:
		print("Error: No Planets node for ", name)
	if not star_node:
		print("Error: No Star node for ", name)
	if not mesh:
		print("Warning: No Mesh for ", name)
	else:
		mesh.transparency = 0.0
	if not collision_shape:
		print("Error: No CollisionShape3D for ", name, "; input detection will fail")
	else:
		input_ray_pickable = true
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	if not star_scene:
		print("Warning: No star_scene for ", name, "; no star will spawn")
	
	popup = ColorRect.new()
	popup.size = Vector2(200, 100)
	popup.color = Color(0.2, 0.2, 0.2, 0.8)
	var label = Label.new()
	label.name = "SystemLabel"
	popup.add_child(label)
	add_child(popup)
	popup.hide()

func _process(delta):
	if zoom_state == ZoomState.ZOOMING_IN:
		transition_timer += delta
		var t = transition_timer / transition_duration
		if mesh:
			mesh.transparency = t
		for planet in planets_node.get_children():
			planet.scale = Vector3.ZERO.lerp(Vector3.ONE, t)
			var planet_mesh = planet.get_node("MeshInstance3D") if planet.has_node("MeshInstance3D") else planet.get_node("Mesh")
			if planet_mesh:
				planet_mesh.transparency = 1.0 - t
			planet.visible = true
		for star in star_node.get_children():
			star.scale = Vector3.ZERO.lerp(Vector3.ONE, t)
			var star_mesh = star.get_node("MeshInstance3D") if star.has_node("MeshInstance3D") else null
			if star_mesh:
				star_mesh.transparency = 1.0 - t
			star.visible = true
		if t >= 1.0:
			if mesh:
				mesh.visible = false
			if collision_shape:
				collision_shape.disabled = true
				input_ray_pickable = false
			zoom_state = ZoomState.IDLE
			transition_timer = 0.0
			popup.hide()
			planets = get_planets()
			current_planet_index = 0
			update_planet_tooltip()
	elif zoom_state == ZoomState.ZOOMING_OUT:
		transition_timer += delta
		var t = transition_timer / transition_duration
		if mesh:
			mesh.transparency = 1.0 - t
			mesh.visible = true
		for planet in planets_node.get_children():
			planet.scale = Vector3.ONE.lerp(Vector3.ZERO, t)
			var planet_mesh = planet.get_node("MeshInstance3D") if planet.has_node("MeshInstance3D") else planet.get_node("Mesh")
			if planet_mesh:
				planet_mesh.transparency = t
			planet.visible = true
		for star in star_node.get_children():
			star.scale = Vector3.ONE.lerp(Vector3.ZERO, t)
			var star_mesh = star.get_node("MeshInstance3D") if star.has_node("MeshInstance3D") else null
			if star_mesh:
				star_mesh.transparency = t
			star.visible = true
		if t >= 1.0:
			for planet in planets_node.get_children():
				planet.queue_free()
			for star in star_node.get_children():
				star.queue_free()
			if collision_shape:
				collision_shape.disabled = false
				input_ray_pickable = true
			zoom_state = ZoomState.IDLE
			transition_timer = 0.0
			is_perks_active = false
			planets = []
			current_planet_index = 0
			if planet_tooltip:
				planet_tooltip.visible = false
	
	if zoom_state == ZoomState.IDLE and not is_perks_active and Input.is_action_just_pressed("select"):
		for planet in planets_node.get_children():
			if planet.get_meta("hovered", false):
				is_perks_active = true
				emit_signal("planet_selected", planet.get_planet_data())
				break

func _input(event):
	if zoom_state == ZoomState.IDLE and not is_perks_active and planets.size() > 0:
		if Input.is_action_just_pressed("navigate_right"):
			current_planet_index = (current_planet_index + 1) % planets.size()
			update_planet_tooltip()
		elif Input.is_action_just_pressed("navigate_left"):
			current_planet_index = (current_planet_index - 1) % planets.size()
			if current_planet_index < 0:
				current_planet_index = planets.size() - 1
			update_planet_tooltip()
		elif Input.is_action_just_pressed("select"):
			var planet_data = planets[current_planet_index]
			if GameState.get_points() >= planet_data["points_required"]:
				is_perks_active = true
				emit_signal("planet_selected", planet_data)

func initialize_ui(_planet_tooltip, _tooltip_label):
	planet_tooltip = _planet_tooltip
	tooltip_label = _tooltip_label

func get_system_data():
	return {
		"name": system_name if system_name else name,
		"difficulty": difficulty,
		"points_required": points_required,
		"planets": planet_scenes
	}

func get_planets():
	var planet_data_array = []
	for planet in planets_node.get_children():
		if planet.has_method("get_planet_data"):
			planet_data_array.append(planet.get_planet_data())
		else:
			print("Warning: Planet ", planet.name, " has no get_planet_data method")
	return planet_data_array

func start_zoom_in():
	spawn_planets()
	zoom_state = ZoomState.ZOOMING_IN
	transition_timer = 0.0
	emit_signal("spawn_complete")
	popup.hide()

func start_zoom_out():
	zoom_state = ZoomState.ZOOMING_OUT
	transition_timer = 0.0
	if mesh:
		mesh.visible = true
	if planet_tooltip:
		planet_tooltip.visible = false

func spawn_planets():
	for planet in planets_node.get_children():
		planet.queue_free()
	for star in star_node.get_children():
		star.queue_free()
	
	var distance = target_zoom_distance
	var fov = deg_to_rad(70.0)
	var aspect = get_viewport().get_visible_rect().size.x / get_viewport().get_visible_rect().size.y
	var frustum_width = 2.0 * distance * tan(fov / 2.0) * aspect
	var left_frustum_x = -frustum_width / 2.0
	
	var current_offset = 0.0
	if star_scene and star_node:
		var star = star_scene.instantiate()
		star.name = "Star"
		
		var star_mesh = star.get_node("MeshInstance3D") if star.has_node("MeshInstance3D") else null
		var star_radius = 1.0
		if star_mesh and star_mesh.mesh:
			if star_mesh.mesh is SphereMesh:
				star_radius = star_mesh.mesh.radius * star_mesh.scale.x
			else:
				var aabb = star_mesh.mesh.get_aabb()
				star_radius = aabb.size.x * star_mesh.scale.x / 2.0
			print("Star radius: ", star_radius)
		
		star.position = Vector3(left_frustum_x + star_radius, 0, 0)
		current_offset = left_frustum_x + star_radius * 2.0 + 4.0
		star.scale = Vector3.ZERO
		if star_mesh:
			star_mesh.transparency = 1.0
		star.visible = true
		star_node.add_child(star)
		print("Left frustum x: ", left_frustum_x, " Star pos: ", star.position, " Offset: ", current_offset)
	
	for planet_scene in planet_scenes:
		var planet = planet_scene.instantiate()
		var collision = planet.get_node("CollisionShape3D")
		var radius = collision.shape.radius if collision and collision.shape is SphereShape3D else 0.5
		current_offset += radius
		planet.position = Vector3(current_offset, 0, 0)
		current_offset += radius + 1.0
		planet.scale = Vector3.ZERO
		var planet_mesh = planet.get_node("MeshInstance3D") if planet.has_node("MeshInstance3D") else planet.get_node("Mesh")
		if planet_mesh:
			planet_mesh.transparency = 1.0
		planet.visible = true
		planets_node.add_child(planet)
		planet.mouse_entered.connect(_on_planet_hover.bind(planet.get_planet_data()["name"], true))
		planet.mouse_exited.connect(_on_planet_hover.bind(planet.get_planet_data()["name"], false))
		planet.set_meta("hovered", false)

func _on_planet_hover(planet_name, entered):
	if is_perks_active:
		return
	if planet_tooltip and tooltip_label:
		if entered:
			var planet = planets_node.get_children().filter(func(p): return p.get_planet_data()["name"] == planet_name)[0]
			planet.set_meta("hovered", true)
			tooltip_label.text = get_planet_tooltip_text(planet.get_planet_data())
			planet_tooltip.visible = true
			update_planet_tooltip_position(planet)
		else:
			var planet = planets_node.get_children().filter(func(p): return p.get_planet_data()["name"] == planet_name)[0]
			planet.set_meta("hovered", false)
			planet_tooltip.visible = false

func get_planet_tooltip_text(planet_data: Dictionary) -> String:
	var text = planet_data["name"]
	if GameState.get_points() < planet_data["points_required"]:
		text += "\nLocked (Need %d points)" % planet_data["points_required"]
	else:
		text += "\nType: %s" % planet_data["planet_type"]
		text += "\nWaves: %d" % planet_data["waves"]
		text += "\nResistance: %s" % planet_data["resistance"]
		var day_duration = planet_data.get("day_duration", 45.0)
		text += "\nDay/Night Cycle: %.1f sec" % day_duration
		if planet_data.has("extra_info"):
			text += "\n%s" % planet_data["extra_info"]
	return text

func start_perks_mode():
	is_perks_active = true
	if planet_tooltip:
		planet_tooltip.visible = false

func end_perks_mode():
	is_perks_active = false
	if zoom_state == ZoomState.IDLE and planets.size() > 0:
		update_planet_tooltip()

func reset_perks_active():
	is_perks_active = false
	popup.hide()
	if planet_tooltip:
		planet_tooltip.visible = false
	print("Reset is_perks_active for system: ", system_name)

func update_planet_tooltip_position(planet):
	if planet_tooltip:
		var camera = get_viewport().get_camera_3d()
		var screen_pos = camera.unproject_position(planet.global_position + Vector3(0, 1, 0))
		var tooltip_size = planet_tooltip.size
		planet_tooltip.position = screen_pos - Vector2(tooltip_size.x / 2, tooltip_size.y + 25)

func update_planet_tooltip():
	if planets.size() > 0 and planet_tooltip and tooltip_label:
		var planet_data = planets[current_planet_index]
		tooltip_label.text = get_planet_tooltip_text(planet_data)
		planet_tooltip.visible = true
		var planet = planets_node.get_children()[current_planet_index]
		update_planet_tooltip_position(planet)
	elif planet_tooltip:
		planet_tooltip.visible = false

func _on_mouse_entered():
	if zoom_state == ZoomState.IDLE:
		update_system_ui()
		var screen_pos = get_viewport().get_camera_3d().unproject_position(global_position + Vector3(0, 2, 0))
		popup.position = screen_pos - Vector2(popup.size.x / 2, popup.size.y + 25)
		popup.show()

func _on_mouse_exited():
	popup.hide()

func update_system_ui():
	var completed = planet_scenes.filter(func(p): return GameState.is_planet_completed(p.instantiate().get_planet_data()["name"])).size()
	var total = planet_scenes.size()
	var text = "%s\nDifficulty: %s\nProgress: %d/%d" % [system_name, difficulty, completed, total]
	if GameState.get_points() < points_required:
		text += "\nLocked (Need %d points)" % points_required
	popup.get_node("SystemLabel").text = text
