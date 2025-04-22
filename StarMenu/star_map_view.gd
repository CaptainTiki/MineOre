extends Node3D

signal system_selected(system)

var highlighted_system: Node3D = null
var highlight_sprite: Sprite3D = null
var vertical_line: MeshInstance3D = null
var panel_line_mesh: MeshInstance3D = null

@onready var system_name_label = $UI/SystemInfoPanel/InfoContainer/SystemNameLabel
@onready var difficulty_label = $UI/SystemInfoPanel/InfoContainer/DifficultyLabel
@onready var progress_label = $UI/SystemInfoPanel/InfoContainer/ProgressLabel
@onready var description_label = $UI/SystemInfoPanel/InfoContainer/DescriptionLabel
@onready var locked_label = $UI/SystemInfoPanel/InfoContainer/LockedLabel
@onready var system_info_panel = $UI/SystemInfoPanel

func _ready():
	# Initialize highlight sprite
	highlight_sprite = Sprite3D.new()
	highlight_sprite.texture = preload("res://assets/ring.png")
	highlight_sprite.scale = Vector3(3.0, 3.0, 3.0)
	highlight_sprite.translate(Vector3(0, 0.5, 0))
	highlight_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	highlight_sprite.visible = false
	add_child(highlight_sprite)
	
	# Initialize vertical line (3D)
	vertical_line = MeshInstance3D.new()
	vertical_line.mesh = ImmediateMesh.new()
	vertical_line.visible = false
	add_child(vertical_line)
	
	# Initialize panel line (3D)
	panel_line_mesh = MeshInstance3D.new()
	panel_line_mesh.mesh = ImmediateMesh.new()
	panel_line_mesh.visible = false
	add_child(panel_line_mesh)
	
	# Hide panel initially
	system_info_panel.visible = false

func set_systems(systems_node: Node3D):
	for system in systems_node.get_children():
		if system is Node3D and system.has_signal("clicked"):
			system.connect("clicked", _on_system_clicked)
			system.connect("mouse_entered", _on_system_mouse_entered.bind(system))
			system.connect("mouse_exited", _on_system_mouse_exited.bind(system))
	
	# Automatically highlight the first system
	var systems = systems_node.get_children()
	if systems.size() > 0:
		systems.sort_custom(func(a, b): return a.position.y > b.position.y)
		_on_system_mouse_entered(systems[0])
	
	call_deferred("_start_animation", systems_node)

func _input(event):
	if event.is_action_pressed("navigate_left"):
		navigate_to_next_system("x", -1)
	elif event.is_action_pressed("navigate_right"):
		navigate_to_next_system("x", 1)
	elif event.is_action_pressed("navigate_up"):
		navigate_to_next_system("y", 1)
	elif event.is_action_pressed("navigate_down"):
		navigate_to_next_system("y", -1)

func navigate_to_next_system(axis: String, direction: int):
	if not highlighted_system:
		return
	
	var systems = get_node("/root/StarMenu/StarSystems").get_children()
	if systems.size() <= 1:
		return
	
	if axis == "x":
		systems.sort_custom(func(a, b): return a.position.x < b.position.x)
	else:
		systems.sort_custom(func(a, b): return a.position.y < b.position.y)
	
	var current_index = systems.find(highlighted_system)
	if current_index == -1:
		return
	
	var next_index = current_index + direction
	if next_index < 0:
		next_index = systems.size() - 1
	elif next_index >= systems.size():
		next_index = 0
	
	_on_system_mouse_entered(systems[next_index])

func _on_system_clicked(resource: StarSystemResource):
	emit_signal("system_selected", resource)

func _start_animation(systems_node: Node3D):
	var systems = systems_node.get_children()
	systems.sort_custom(func(a, b): return a.position.y > b.position.y)
	
	var delay_per_system = 0.15
	for i in systems.size():
		await get_tree().create_timer(delay_per_system).timeout
		var system = systems[i]
		system.visible = false
		system.play_anim("blink_on_animation")
	
	# Start constellation lines after stars finish (1.6s total)
	await get_tree().create_timer(1.6).timeout
	animate_constellation_lines()

func animate_constellation_lines():
	var lines = get_node("/root/StarMenu/ConstellationLines").get_children()
	# Sort by the higher y-position of start or end node
	lines.sort_custom(func(a, b):
		var a_start = a.get_node_or_null(a.start_node)
		var a_end = a.get_node_or_null(a.end_node)
		var b_start = b.get_node_or_null(b.start_node)
		var b_end = b.get_node_or_null(b.end_node)
		var a_y = max(a_start.global_transform.origin.y if a_start else -INF, a_end.global_transform.origin.y if a_end else -INF)
		var b_y = max(b_start.global_transform.origin.y if b_start else -INF, b_end.global_transform.origin.y if b_end else -INF)
		return a_y > b_y
	)
	
	var delay_per_line = 0.15
	for i in lines.size():
		await get_tree().create_timer(delay_per_line).timeout
		var line = lines[i]
		line.play_anim("blink_on_animation")  # Animation now handles visibility

func _on_system_mouse_entered(system: Node3D):
	if system.resource:
		highlighted_system = system
		update_ui(system.resource)
		highlight_sprite.visible = true
		highlight_sprite.global_transform.origin = system.global_transform.origin + Vector3(0, 0.5, 0)
		animate_lines(system.global_transform.origin + Vector3(0, 0.5, 0))

func _on_system_mouse_exited(system: Node3D):
	if highlighted_system == system:
		highlighted_system = null
		clear_ui()
		highlight_sprite.visible = false
		vertical_line.visible = false
		panel_line_mesh.visible = false
		system_info_panel.visible = false

func update_ui(resource: StarSystemResource):
	system_name_label.text = resource.system_name
	difficulty_label.text = "Difficulty: %d" % resource.difficulty
	progress_label.text = "Progress: 0 / %d" % resource.planets.size()
	description_label.text = "Description: %s" % resource.description
	locked_label.text = "Locked: %s" % ("Yes" if resource.locked else "No")

func clear_ui():
	system_name_label.text = "Select a system"
	difficulty_label.text = "Difficulty: -"
	progress_label.text = "Progress: -"
	description_label.text = "Description: -"
	locked_label.text = "Locked: -"

func animate_lines(start_pos: Vector3):
	vertical_line.visible = false
	panel_line_mesh.visible = false
	system_info_panel.visible = false
	
	var camera = get_viewport().get_camera_3d()
	var screen_pos = camera.unproject_position(start_pos)
	var screen_end_pos = screen_pos + Vector2(0, -100)
	var vertical_end_pos = camera.project_position(screen_end_pos, camera.global_transform.origin.z - start_pos.z)
	
	vertical_line.mesh.clear_surfaces()
	vertical_line.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	vertical_line.mesh.surface_add_vertex(start_pos)
	vertical_line.mesh.surface_add_vertex(start_pos)
	vertical_line.mesh.surface_end()
	vertical_line.visible = true
	
	var panel_screen_pos = system_info_panel.get_global_rect().position + Vector2(0, system_info_panel.get_global_rect().size.y)
	var panel_world_pos = camera.project_position(panel_screen_pos, camera.global_transform.origin.z - start_pos.z)
	panel_line_mesh.mesh.clear_surfaces()
	panel_line_mesh.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	panel_line_mesh.mesh.surface_add_vertex(vertical_end_pos)
	panel_line_mesh.mesh.surface_add_vertex(vertical_end_pos)
	panel_line_mesh.mesh.surface_end()
	
	var tween = create_tween()
	tween.tween_method(
		func(t): 
			vertical_line.mesh.clear_surfaces()
			vertical_line.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			vertical_line.mesh.surface_add_vertex(start_pos)
			vertical_line.mesh.surface_add_vertex(start_pos.lerp(vertical_end_pos, t))
			vertical_line.mesh.surface_end(),
		0.0, 1.0, 0.25
	)
	
	tween.tween_callback(func(): panel_line_mesh.visible = true)
	tween.tween_method(
		func(t):
			panel_line_mesh.mesh.clear_surfaces()
			panel_line_mesh.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			panel_line_mesh.mesh.surface_add_vertex(vertical_end_pos)
			panel_line_mesh.mesh.surface_add_vertex(vertical_end_pos.lerp(panel_world_pos, t))
			panel_line_mesh.mesh.surface_end(),
		0.0, 1.0, 0.25
	)
	
	tween.tween_callback(func(): system_info_panel.visible = true)
