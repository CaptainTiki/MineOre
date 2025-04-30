# res://scripts/gun.gd
extends Node3D

var bullet_scene = preload("res://scenes/bullet.tscn")
var fire_rate = 0.3 # Seconds between shots
var fire_timer = 0.0
var is_firing = false

func _process(delta: float):
	fire_timer += delta
	if fire_timer >= fire_rate:
		fire_timer = fire_rate * 2 #keeps fire rate from going to an error state
	if is_firing:
		if fire_timer >= fire_rate:
			fire_timer = 0.0 # Reset timer
			# Fire bullet (will be triggered again if still pressed)
			shoot_bullet()

func use_tool(player: CharacterBody3D, is_pressed: bool):
	is_firing = is_pressed

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	var level = get_tree().root.get_node_or_null("Level")
	level.add_child(bullet)
	bullet.global_position = global_position
	var bullet_speed = 20.0
	var forward_dir = -get_parent().transform.basis.z.normalized()
	bullet.velocity = forward_dir * bullet_speed
