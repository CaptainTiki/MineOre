# res://scripts/build_repair_tool.gd
extends Node3D
class_name BuildRepairTool

@export var player: Player
@onready var repair_beam = $RepairBeam
@onready var raycast = $RayCast3D
@onready var mesh_instance_3d: CSGBox3D = $RepairBeam/MeshInstance3D
@onready var construction_menu = %ConstructionMenu

var repair_effect_scene = preload("res://scenes/repair_effect.tscn")
var repair_timer = 0.0
var repair_rate = 0.1  # Seconds per 1 HP repair (10 HP/sec)
var particle_timer = 0.0
var particle_rate = 0.2  # Seconds between particle spawns
var is_repairing = false
var current_building = null

func _ready():
	visible = false
	repair_beam.emitting = false
	mesh_instance_3d.visible = false
	raycast.enabled = true
	raycast.visible = true
	if not player:
		push_error("Player node not found in BuildRepairTool")
	if not construction_menu:
		push_error("ConstructionMenu not found in BuildRepairTool")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("construction_menu"):
		if construction_menu.visible:
			construction_menu.hide_menu()
		else:
			construction_menu.show_menu()

	if is_repairing and current_building and is_instance_valid(current_building):
		repair_timer += delta
		particle_timer += delta
		if repair_timer >= repair_rate:
			if current_building.has_method("repair"):
				current_building.repair(1)
			repair_timer = 0.0
		if particle_timer >= particle_rate:
			var repair_effect = repair_effect_scene.instantiate()
			var level = player.get_tree().root.get_node("Level")
			if level:
				level.add_child(repair_effect)
				if repair_effect and current_building:
					repair_effect.global_position = current_building.global_position
			particle_timer = 0.0
		if not raycast.is_colliding() or raycast.get_collider() != current_building:
			stop_repairing()
		else:
			repair_beam.global_position = global_position
			repair_beam.look_at(current_building.global_position, Vector3.UP)
	elif is_repairing:
		stop_repairing()

func use_tool(_player: CharacterBody3D, is_pressed: bool):
	if is_pressed:
		start_repairing()
	else:
		stop_repairing()

func start_repairing():
	raycast.enabled = true
	raycast.visible = true
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("buildings"):
			current_building = collider
			is_repairing = true
			repair_beam.emitting = true
			mesh_instance_3d.visible = true
			var building_pos = current_building.global_position
			repair_beam.global_position = global_position
			repair_beam.look_at(building_pos, Vector3.UP)

func stop_repairing():
	is_repairing = false
	current_building = null
	repair_beam.emitting = false
	mesh_instance_3d.visible = false
	raycast.enabled = false
	raycast.visible = false
