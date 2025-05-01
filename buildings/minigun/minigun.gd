# res://buildings/minigun/minigun.gd
extends Turret

var class_fire_rate = 0.075
var class_rotation_speed = 3.0
var class_damage = 1.0

func _ready():
	super._ready()
	fire_rate = PerksManager.get_modified_stat(class_fire_rate, "turret_fire_rate")
	rotation_speed = PerksManager.get_modified_stat(class_rotation_speed, "turret_rotation_speed")
	damage = PerksManager.get_modified_stat(class_damage, "turret_damage")
	fire_timer = fire_rate
