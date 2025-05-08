# res://scripts/buildings_manager.gd
extends Node

signal building_placed(building: Building, position: Vector3)

var building_configs = {}
var unlocked_buildings = []
var locked_buildings = []
var globally_unlocked_buildings = []
var built_buildings: Array[Building] = []
var is_placing: bool = false

func _ready():
	load_buildings()
	var construction_menu = get_tree().get_root().get_node_or_null("Level/UI/ConstructionMenu")
	if construction_menu:
		construction_menu.building_placed.connect(_on_construction_menu_building_placed)
	else:
		push_error("ConstructionMenu not found in BuildingsManager")

func load_buildings():
	var dir = DirAccess.open("res://buildings/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var resource = load("res://buildings/" + file_name) as BuildingResource
				if resource:
					var building_name = resource.building_name
					building_configs[building_name] = {
						"scene": resource.scene_path,
						"category": resource.category,
						"cost": resource.build_cost,
						"unique": resource.is_unique,
						"is_locked": resource.is_locked and not (building_name in globally_unlocked_buildings),
						"dependencies": resource.dependencies
					}
					if building_name in globally_unlocked_buildings or not resource.is_locked:
						unlocked_buildings.append(building_name)
					else:
						locked_buildings.append(building_name)
				else:
					push_warning("Failed to load resource: %s" % file_name)
			file_name = dir.get_next()
	else:
		push_error("Failed to open res://buildings/")

func _on_construction_menu_building_placed(building_name: String, position: Vector3):
	# Wait for the construction to complete and the final building to be instantiated
	var construction_node = get_tree().root.get_node_or_null("Level/Buildings").get_children().filter(
		func(node): return node is Node3D and node.global_position == position and node.building_resource and node.building_resource.building_name == building_name
	).pop_front()
	if construction_node:
		construction_node.connect("tree_exited", _on_construction_completed.bind(building_name, position))

func _on_construction_completed(building_name: String, position: Vector3):
	var building = get_tree().root.get_node_or_null("Level/Buildings").get_children().filter(
		func(node): return node is Building and node.global_position == position and node.resource and node.resource.building_name == building_name
	).pop_front()
	if building:
		register_building_placed(building)

func register_building_placed(new_building: Building):
	if new_building and new_building.resource and new_building.resource.building_name:
		if new_building not in built_buildings:
			built_buildings.append(new_building)
			emit_signal("building_placed", new_building, new_building.global_position)
			print("Building registered: %s at %s" % [new_building.resource.building_name, new_building.global_position])

func remove_placed_building(building_to_remove: Building):
	if building_to_remove in built_buildings:
		built_buildings.erase(building_to_remove)
		print("Removed building: %s, Built buildings: %s" % [building_to_remove.resource.building_name, built_buildings])

func reset_for_mission():
	unlocked_buildings.clear()
	locked_buildings.clear()
	built_buildings.clear()
	is_placing = false
	for building_name in building_configs:
		var config = building_configs[building_name]
		if building_name in globally_unlocked_buildings or not config.is_locked:
			unlocked_buildings.append(building_name)
		else:
			locked_buildings.append(building_name)

func are_dependencies_met(building_name: String) -> bool:
	if building_name not in building_configs:
		return false
	var config = building_configs[building_name]
	for dep in config.dependencies:
		var dep_met = false
		for built in built_buildings:
			if built.resource and built.resource.building_name == dep:
				dep_met = true
				break
		if not dep_met:
			return false
	return true

func get_building_resource(building_name: String) -> BuildingResource:
	var file_name = "res://buildings/%s.tres" % building_name
	if ResourceLoader.exists(file_name):
		return load(file_name) as BuildingResource
	return null

func is_placing_bldg() -> bool:
	return is_placing
