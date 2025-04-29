# res://scripts/buildings_manager.gd
extends Node

var building_configs = {}
var unlocked_buildings = []  # Buildings buildable in the current mission
var locked_buildings = []
var globally_unlocked_buildings = []
var built_buildings: Array[String] = []  # Track buildings placed in the level

func _ready():
	load_buildings()

func load_buildings():
	var dir = DirAccess.open("res://buildings/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var resource = load("res://buildings/" + file_name) as BuildingResource
				if resource and validate_resource(resource):
					var building_name = resource.building_name
					building_configs[building_name] = {
						"scene": resource.scene_path,
						"category": resource.category,
						"cost": resource.build_cost,
						"unique": resource.is_unique,
						"is_locked": resource.is_locked,
						"dependencies": resource.dependencies  # Store dependencies
					}
					if not resource.is_locked:
						unlocked_buildings.append(building_name)
					else:
						locked_buildings.append(building_name)
				else:
					push_warning("Invalid or failed to load resource: %s" % file_name)
			file_name = dir.get_next()
	else:
		push_error("Failed to open res://buildings/")

func register_building_placed(building_name: String):
	if building_name in building_configs and building_name not in built_buildings:
		built_buildings.append(building_name)
		print("Registered building: %s" % building_name)

func reset_for_mission():
	unlocked_buildings = []
	built_buildings = []  # Clear built buildings
	for building_name in building_configs:
		var config = building_configs[building_name]
		if not config.is_locked:
			unlocked_buildings.append(building_name)
	print("Reset mission buildings: ", unlocked_buildings)

func are_dependencies_met(building_name: String) -> bool:
	if building_name not in building_configs:
		return false
	var config = building_configs[building_name]
	for dep in config.dependencies:
		if dep not in built_buildings:
			return false
	return true

func get_building_resource(building_name: String) -> BuildingResource:
	var file_name = "res://buildings/%s.tres" % building_name
	if ResourceLoader.exists(file_name):
		return load(file_name) as BuildingResource
	return null

func validate_resource(resource: BuildingResource) -> bool:
	if not resource.building_name or resource.building_name == "":
		return false
	if not resource.scene_path or not ResourceLoader.exists(resource.scene_path):
		return false
	var scene = load(resource.scene_path) as PackedScene
	if not scene:
		return false
	var instance = scene.instantiate()
	var valid = instance is StaticBody3D and instance.has_node("MeshInstance3D") and instance.has_node("CollisionShape3D")
	if not valid:
		print("Validation failed: %s, missing StaticBody3D or nodes (MeshInstance3D, CollisionShape3D)" % resource.building_name)
	instance.free()
	return valid
