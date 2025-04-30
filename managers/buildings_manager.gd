# res://scripts/buildings_manager.gd
extends Node

var building_configs = {}
var unlocked_buildings = []
var locked_buildings = []
var globally_unlocked_buildings = []
var built_buildings: Array[String] = []

func _ready():
	load_buildings()

func load_buildings():
	var dir = DirAccess.open("res://buildings/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				print("Loading building: %s" % file_name)
				var resource = load("res://buildings/" + file_name) as BuildingResource
				if resource:
					var building_name = resource.building_name
					building_configs[building_name] = {
						"scene": resource.scene_path,
						"category": resource.category,
						"cost": resource.build_cost,
						"unique": resource.is_unique,
						"is_locked": resource.is_locked and not (building_name in globally_unlocked_buildings), # Override is_locked
						"dependencies": resource.dependencies
					}
					# Unlock if purchased, regardless of resource.is_locked
					if building_name in globally_unlocked_buildings or not resource.is_locked:
						unlocked_buildings.append(building_name)
					else:
						locked_buildings.append(building_name)
				else:
					push_warning("Failed to load resource: %s" % file_name)
			file_name = dir.get_next()
		print("Loaded building_configs: %s" % building_configs.keys())
	else:
		push_error("Failed to open res://buildings/")

func register_building_placed(building_name: String):
	if building_name in building_configs and building_name not in built_buildings:
		built_buildings.append(building_name)
		print("Registered building: %s, built_buildings: %s" % [building_name, built_buildings])

func reset_for_mission():
	unlocked_buildings.clear()
	locked_buildings.clear()
	built_buildings.clear()
	for building_name in building_configs:
		var config = building_configs[building_name]
		# Ensure purchased buildings are unlocked
		if building_name in globally_unlocked_buildings or not config.is_locked:
			unlocked_buildings.append(building_name)
		else:
			locked_buildings.append(building_name)
	print("Reset mission buildings: %s, locked_buildings: %s" % [unlocked_buildings, locked_buildings])

func are_dependencies_met(building_name: String) -> bool:
	if building_name not in building_configs:
		print("Dependency check failed: %s not in building_configs" % building_name)
		return false
	var config = building_configs[building_name]
	for dep in config.dependencies:
		if dep not in built_buildings:
			print("Dependency check failed: %s requires %s, built_buildings: %s" % [building_name, dep, built_buildings])
			return false
	print("Dependencies met for %s" % building_name)
	return true

func get_building_resource(building_name: String) -> BuildingResource:
	var file_name = "res://buildings/%s.tres" % building_name
	if ResourceLoader.exists(file_name):
		return load(file_name) as BuildingResource
	return null
