# res://buildings/building_construction_scene.gd
extends Node3D

@onready var construction_timer = $ConstructionTimer
@onready var mesh_instance = $MeshInstance3D
@onready var construction_shader = preload("res://shaders/construction_shader.gdshader")

var original_materials: Array = []
var final_building_scene: PackedScene
var building_resource: BuildingResource

func load_construction_node(): 
	if building_resource and final_building_scene:
		var temp_building = final_building_scene.instantiate()
		var building_mesh_instance = temp_building.get_node("MeshInstance3D")
		if building_mesh_instance and building_mesh_instance.mesh:
			mesh_instance.mesh = building_mesh_instance.mesh
			original_materials.clear()
			for i in range(building_mesh_instance.mesh.get_surface_count()):
				var material = building_mesh_instance.mesh.surface_get_material(i)
				original_materials.append(material)
		else:
			print("Error: No MeshInstance3D or mesh found in final building")
		temp_building.queue_free()

		construction_timer.wait_time = max(building_resource.construction_time, 0.01)
		construction_timer.start()
		setup_construction_shader()
	else:
		print("Error: Missing building_resource or final_building_scene")
		queue_free()

func setup_construction_shader():
	print("Setting up construction shader for ", mesh_instance.mesh.get_surface_count(), " surfaces")
	for i in range(mesh_instance.mesh.get_surface_count()):
		var original_material = original_materials[i] if i < original_materials.size() else null
		var construction_material = ShaderMaterial.new()
		var shader = construction_shader
		if shader:
			construction_material.shader = shader
		else:
			print("Error: Failed to load shader at res://shaders/construction_shader.tres")
			continue
		
		construction_material.set_shader_parameter("hologram_color", Color(0, 0.5, 1.0, 0.5))
		construction_material.set_shader_parameter("glow_intensity", 0.65)
		construction_material.set_shader_parameter("scanline_speed", 6.0)
		construction_material.set_shader_parameter("scanline_density", 150.0)
		construction_material.set_shader_parameter("flicker_frequency", 18.0)
		construction_material.set_shader_parameter("final_texture", original_material.albedo_texture if original_material is StandardMaterial3D and original_material.albedo_texture else null)
		construction_material.set_shader_parameter("final_color", original_material.albedo_color if original_material is StandardMaterial3D else Color(0.5, 0.5, 0.5))
		var aabb = mesh_instance.get_aabb()
		construction_material.set_shader_parameter("min_y", aabb.position.y)
		construction_material.set_shader_parameter("max_y", aabb.position.y + aabb.size.y)
		
		mesh_instance.set_surface_override_material(i, construction_material)

func _process(_delta):
	if construction_timer.time_left > 0:
		var progress = 1.0 - (construction_timer.time_left / building_resource.construction_time)
		for i in range(mesh_instance.mesh.get_surface_count()):
			var material = mesh_instance.get_surface_override_material(i)
			if material:
				material.set_shader_parameter("progress", progress)

func _on_construction_timer_timeout():
	if final_building_scene:
		var buildings_node = get_tree().root.get_node("Level/Buildings")
		var final_building = final_building_scene.instantiate()
		buildings_node.add_child(final_building)
		final_building.global_position = global_position
		final_building.resource = building_resource
		
		final_building.owner = get_tree().root.get_node("Level")
		print("Construction complete: %s" % building_resource.building_name)
		final_building.on_placed()
		queue_free()
	else:
		print("Error: final_building_scene not set")
		queue_free()
