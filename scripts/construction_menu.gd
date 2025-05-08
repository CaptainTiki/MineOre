# res://scripts/construction_menu.gd
extends Control

signal building_placed(building_name: String, position: Vector3)
signal placement_failed(building_name: String, reason: String)

@onready var vbox_container = $VBoxContainer
@onready var player = get_tree().get_root().get_node_or_null("Level/Player") as Player
var placed_uniques = []
var current_button_index = 0
var buttons = []

# Building placement variables
var is_placing = false
var preview_instance = null
var preview_scene_path = ""
var preview_building_name = ""
var preview_distance = 4.0
var grid_size = 2.0
var preview_material = null

func _ready():
	visible = false
	if not player:
		push_error("Player node not found in ConstructionMenu")
	BuildingsManager.building_placed.connect(_on_building_placed)
	update_menu()

func _input(_event):
	if visible:
		if Input.is_action_just_pressed("navigate_down"):
			current_button_index = (current_button_index + 1) % buttons.size()
			update_button_focus()
		elif Input.is_action_just_pressed("navigate_up"):
			current_button_index = (current_button_index - 1) % buttons.size()
			if current_button_index < 0:
				current_button_index = buttons.size() - 1
			update_button_focus()
		elif Input.is_action_just_pressed("select") and buttons.size() > 0:
			var button = buttons[current_button_index]
			if not button.disabled:
				button.emit_signal("pressed")
		elif Input.is_action_just_pressed("cancel"):
			hide_menu()

	if is_placing and preview_instance:
		update_preview_position()
		if Input.is_action_just_pressed("use_tool"):
			place_building()
		if Input.is_action_just_pressed("cancel"):
			cancel_placement()

func show_menu():
	visible = true
	update_menu()
	if buttons.size() > 0:
		current_button_index = 0
		update_button_focus()

func hide_menu():
	visible = false
	cancel_placement()

func update_menu():
	buttons.clear()
	for child in vbox_container.get_children():
		child.queue_free()
	
	var categories = {}
	for building in BuildingsManager.building_configs:
		var config = BuildingsManager.building_configs[building]
		var resource = BuildingsManager.get_building_resource(building)
		if resource:
			var is_purchased = true
			if building in ["refinery", "ordnance_facility", "minigun"]:
				is_purchased = StoreManager.is_purchased("building", building)
			var ui_is_visible = (building in BuildingsManager.unlocked_buildings and
							   BuildingsManager.are_dependencies_met(building) and
							   is_purchased)
			if ui_is_visible:
				var button = Button.new()
				button.text = "%s (%d ore)" % [resource.display_name, config.cost]
				button.focus_mode = Control.FOCUS_ALL
				if resource.is_unique and building in placed_uniques:
					button.disabled = true
					button.modulate = Color(0.5, 0.5, 0.5)
				button.pressed.connect(_on_building_pressed.bind(config.scene, building))
				if not categories.has(config.category):
					categories[config.category] = GridContainer.new()
					categories[config.category].name = config.category.capitalize() + "Grid"
					categories[config.category].columns = 2
					var label = Label.new()
					label.text = config.category.capitalize()
					vbox_container.add_child(label)
					vbox_container.add_child(categories[config.category])
				categories[config.category].add_child(button)
				buttons.append(button)
		else:
			push_warning("No resource for building: %s" % building)

func update_button_focus():
	if buttons.size() > 0:
		buttons[current_button_index].grab_focus()

func _on_building_pressed(scene_path, building_name):
	start_placement(scene_path, building_name)

func _on_building_placed(_building: Building, _position: Vector3):
	update_menu()

func mark_unique_placed(building: String):
	if building in BuildingsManager.building_configs and BuildingsManager.building_configs[building].get("unique", false):
		placed_uniques.append(building)
		update_menu()

func start_placement(scene_path: String, building_name: String):
	hide_menu()
	if is_placing:
		cancel_placement()
	preview_scene_path = scene_path
	preview_building_name = building_name
	preview_instance = load(scene_path).instantiate()
	preview_instance.set_meta("is_preview", true)
	preview_instance.collision_layer = 0
	
	var mesh = preview_instance.get_node("MeshInstance3D")
	if mesh:
		preview_material = StandardMaterial3D.new()
		preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		preview_material.albedo_color = Color(0, 1, 0, 0.65)
		mesh.material_override = preview_material
	
	var base_distance = 4.0
	var shape_size_z = 0.0
	var collision_shape = preview_instance.get_node_or_null("CollisionShape3D")
	if collision_shape and collision_shape.shape is BoxShape3D:
		shape_size_z = collision_shape.shape.extents.z
		preview_distance = base_distance + (shape_size_z / 2.0)
	else:
		preview_distance = base_distance
	
	var level = get_tree().root.get_node("Level")
	level.add_child(preview_instance)
	
	is_placing = true
	BuildingsManager.is_placing = true
	update_preview_position()

func update_preview_position():
	if preview_instance and player:
		var preview_pos = player.global_position + (-player.transform.basis.z.normalized() * preview_distance)
		preview_pos.x = round(preview_pos.x / grid_size) * grid_size
		preview_pos.z = round(preview_pos.z / grid_size) * grid_size
		preview_pos.y = 0
		preview_instance.global_position = preview_pos
		
		if preview_material:
			if check_placement_validity():
				preview_material.albedo_color = Color(0, 1, 0, 0.65)
			else:
				preview_material.albedo_color = Color(1, 0, 0, 0.65)

func check_placement_validity() -> bool:
	if not preview_instance or not preview_scene_path or not player:
		print("Invalid placement: No preview instance, scene path, or player")
		return false
	
	var level = get_tree().root.get_node("Level")
	var is_hq = preview_building_name == "headquarters"
	var hq = level.get_node_or_null("Buildings/HeadQuarters")
	var cost = BuildingsManager.building_configs.get(preview_building_name, {}).get("cost", 0)
	var has_ore = is_hq
	if not is_hq and hq:
		has_ore = hq.stored_ore >= cost
	
	var space_state = player.get_world_3d().direct_space_state
	var shape = preview_instance.get_node_or_null("CollisionShape3D")
	if shape and shape.shape:
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = shape.shape
		query.transform = preview_instance.global_transform
		query.collision_mask = 0b1000100
		query.exclude = [player]
		var result = space_state.intersect_shape(query)
		var is_collision_free = result.size() == 0
		return has_ore and is_collision_free
	
	print("No collision shape for ", preview_building_name)
	return false

func place_building():
	if preview_instance and preview_scene_path:
		var cost = BuildingsManager.building_configs.get(preview_building_name, {}).get("cost", 0)
		var level = get_tree().root.get_node("Level")
		var hq = level.get_node_or_null("Buildings/HeadQuarters")
		if check_placement_validity():
			var withdrawn = 0
			if preview_building_name != "headquarters" and cost > 0:
				withdrawn = hq.withdraw_ore(cost)
			if withdrawn == cost or preview_building_name == "headquarters":
				var buildings_node = level.get_node_or_null("Buildings")
				var construction = load("res://buildings/building_construction_scene.tscn").instantiate()
				buildings_node.add_child(construction)
				construction.global_position = preview_instance.global_position
				construction.building_resource = BuildingsManager.get_building_resource(preview_building_name)
				construction.final_building_scene = load(preview_scene_path)
				construction.owner = level
				construction.load_construction_node()

				emit_signal("building_placed", preview_building_name, construction.global_position)
				
				if preview_building_name == "silo" and hq:
					hq.add_silo()
				if BuildingsManager.building_configs.get(preview_building_name, {}).get("unique", false):
					mark_unique_placed(preview_building_name)
				update_menu()
			else:
				emit_signal("placement_failed", preview_building_name, "Not enough ore")
		else:
			emit_signal("placement_failed", preview_building_name, "Invalid position")
		cancel_placement()
	else:
		emit_signal("placement_failed", preview_building_name, "Invalid placement")
		cancel_placement()

func cancel_placement():
	if preview_instance:
		preview_instance.queue_free()
	is_placing = false
	BuildingsManager.is_placing = false
	preview_scene_path = ""
	preview_building_name = ""
	preview_distance = 4.0
	preview_material = null
