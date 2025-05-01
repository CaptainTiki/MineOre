# res://scripts/ore_chunk.gd
extends Node3D

func _ready():
	$AnimationPlayer.connect("animation_finished", _on_animation_finished)

func _on_animation_finished(_anim_name: String):
	queue_free()
