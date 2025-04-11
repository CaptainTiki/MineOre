extends Node

var level_scene = preload("res://levels/level.tscn")

func _ready():
	var level = level_scene.instantiate()
	add_child(level)
