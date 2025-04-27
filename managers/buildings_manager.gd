# res://scripts/buildings_manager.gd
extends Node

var building_configs = {}
var research_options = {}
var unlocked_buildings = []  # Buildings buildable in the current mission
var locked_buildings = []
var globally_unlocked_buildings = []  # Buildings unlocked through leveling up

var refinery_options = {}

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
				if resource:
					if validate_resource(resource):
						var building_name = resource.building_name
						building_configs[building_name] = {
							"scene": resource.scene_path,
							"category": resource.category,
							"cost": resource.build_cost,
							"unique": resource.is_unique,
							"research_cost": resource.research_cost,
							"research_description": resource.research_description,
							"is_researchable": resource.is_researchable,
							"is_locked": resource.is_locked
						}
						if resource.is_researchable and resource.building_name == "refinery":
							refinery_options["basic_refine"] = {"ore_cost": 2, "refined_ore": 1, "time": 5.0}
						if not resource.is_researchable and not resource.is_locked:
							unlocked_buildings.append(building_name)
						if resource.is_locked:
							locked_buildings.append(building_name)
					else:
						push_warning("Invalid BuildingResource: %s" % file_name)
				else:
					push_warning("Failed to load resource: %s" % file_name)
			file_name = dir.get_next()
	else:
		push_error("Failed to open res://buildings/")
	update_research_options()

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

func research_building(building_name: String):
	if building_name in building_configs and building_name in research_options:
		if building_name in locked_buildings:
			locked_buildings.erase(building_name)
		if building_name not in unlocked_buildings:
			unlocked_buildings.append(building_name)
		research_options.erase(building_name)  # Remove from research options once researched
		GameState.unlocked_buildings = unlocked_buildings
		print("Researched building: %s" % building_name)

func set_globally_unlocked_buildings(unlocked: Array):
	globally_unlocked_buildings = unlocked
	update_research_options()

func update_research_options():
	research_options.clear()
	for building_name in building_configs:
		var config = building_configs[building_name]
		if config.is_researchable and building_name in globally_unlocked_buildings:
			research_options[building_name] = {
				"ore_cost": config.research_cost,
				"description": config.research_description
			}
	print("Updated research options: ", research_options)

func reset_for_mission():
	unlocked_buildings = []
	for building_name in building_configs:
		var config = building_configs[building_name]
		if not config.is_researchable and not config.is_locked:
			unlocked_buildings.append(building_name)
	print("Reset mission buildings: ", unlocked_buildings)

func get_building_resource(building_name: String) -> BuildingResource:
	var file_name = "res://buildings/%s.tres" % building_name
	if ResourceLoader.exists(file_name):
		return load(file_name) as BuildingResource
	return null
