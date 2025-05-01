# res://scripts/mining_laser.gd
extends Node3D

var mining_effect_scene = preload("res://scenes/mining_effect.tscn")
var ore_chunk_scene = preload("res://scenes/ore_chunk.tscn")  # New preload
var mining_timer = 0.0
var mining_rate = 0.3  # Seconds per ore
var particle_timer = 0.0
var particle_rate = 0.2  # Seconds between particle spawns
var is_mining = false
var current_ore_node = null
@onready var laser_beam = $LaserBeam
@onready var cone = $Cone
@onready var mesh_instance_3d: CSGBox3D = $LaserBeam/MeshInstance3D

@export var player : Player

func _ready():
	laser_beam.emitting = false
	mesh_instance_3d.visible = false

func use_tool(player: CharacterBody3D, is_pressed: bool):
	if is_pressed:
		start_mining(player)
	else:
		stop_mining()

func start_mining(player: CharacterBody3D):
	var bodies = cone.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("ores"):
			current_ore_node = body
			is_mining = true
			laser_beam.emitting = true
			mesh_instance_3d.visible = true
			# Rotate beam to face ore
			var ore_pos = current_ore_node.global_position
			laser_beam.global_position = global_position
			laser_beam.look_at(ore_pos, Vector3.UP)
			return
	is_mining = false
	laser_beam.emitting = false
	mesh_instance_3d.visible = false

func stop_mining():
	is_mining = false
	current_ore_node = null
	laser_beam.emitting = false
	mesh_instance_3d.visible = false

func _process(delta: float):
	if is_mining and current_ore_node:
		mining_timer += delta
		particle_timer += delta
		if mining_timer >= mining_rate:
			if player.carried_ore < player.carry_capacity:
				player.carried_ore += 1
				player.emit_signal("ore_carried", 1)
				# Spawn ore chunk
				var ore_chunk = ore_chunk_scene.instantiate()
				var level = player.get_tree().root.get_node("Level")
				level.add_child(ore_chunk)
				if ore_chunk and current_ore_node:
					ore_chunk.global_position = current_ore_node.global_position
				mining_timer = 0.0
			else:
				stop_mining()
		if particle_timer >= particle_rate:
			# Spawn mining effect at ore position
			var mining_effect = mining_effect_scene.instantiate()
			var level = player.get_tree().root.get_node("Level/Ores")
			level.add_child(mining_effect)
			if mining_effect and current_ore_node:
				mining_effect.global_position = current_ore_node.global_position
			particle_timer = 0.0
		if not cone.get_overlapping_bodies().has(current_ore_node):
			stop_mining()
		else:
			# Keep beam aligned with ore
			laser_beam.global_position = global_position
			laser_beam.look_at(current_ore_node.global_position, Vector3.UP)
