# res://scripts/buildings_manager.gd
extends Node

var building_configs = {}
var research_options = {}
var unlocked_buildings = []
var locked_buildings = []

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
				print("Loading: res://buildings/%s" % file_name)
				var resource = load("res://buildings/" + file_name) as BuildingResource
				if resource:
					print("Resource loaded: %s, name: %s" % [file_name, resource.name])
					if validate_resource(resource):
						var name = resource.name
						building_configs[name] = {
							"scene": resource.scene_path,
							"category": resource.category,
							"cost": resource.build_cost,
							"unique": resource.is_unique
						}
						if resource.is_researchable and resource.research_description != "":
							research_options[name] = {
								"ore_cost": resource.research_cost,
								"description": resource.research_description
							}
						if resource.is_researchable and resource.name == "refinery":
							refinery_options["basic_refine"] = {"ore_cost": 2, "refined_ore": 1, "time": 5.0}
						if not resource.is_researchable and not resource.is_locked:
							unlocked_buildings.append(name)
							print("Unlocked: %s" % name)
						if resource.is_locked:
							locked_buildings.append(name)
							print("Locked: %s" % name)
					else:
						push_warning("Invalid BuildingResource: %s" % file_name)
				else:
					push_warning("Failed to load resource: %s" % file_name)
			file_name = dir.get_next()
		print("Final configs: ", building_configs.keys())
		print("Refinery options: ", refinery_options)
	else:
		push_error("Failed to open res://buildings/")

func validate_resource(resource: BuildingResource) -> bool:
	if not resource.name or resource.name == "":
		print("Validation failed: %s, empty name" % resource.resource_path)
		return false
	if not resource.scene_path or not ResourceLoader.exists(resource.scene_path):
		print("Validation failed: %s, invalid scene_path: %s" % [resource.name, resource.scene_path])
		return false
	var scene = load(resource.scene_path) as PackedScene
	if not scene:
		print("Validation failed: %s, scene not found: %s" % [resource.name, resource.scene_path])
		return false
	var instance = scene.instantiate()
	var valid = instance is StaticBody3D and instance.has_node("MeshInstance3D") and instance.has_node("CollisionShape3D")
	if not valid:
		print("Validation failed: %s, missing StaticBody3D or nodes (MeshInstance3D, CollisionShape3D)" % resource.name)
	instance.free()
	return valid

func unlock_building(name: String):
	if name in building_configs:
		if name in locked_buildings:
			locked_buildings.erase(name)
			unlocked_buildings.append(name)
		if name in research_options:
			research_options.erase(name)
			unlocked_buildings.append(name)
		var game_state = get_node_or_null("/root/GameState")
		if game_state:
			game_state.unlocked_buildings = unlocked_buildings

func get_building_resource(name: String) -> BuildingResource:
	var file_name = "res://buildings/%s.tres" % name
	if ResourceLoader.exists(file_name):
		return load(file_name) as BuildingResource
	return null
