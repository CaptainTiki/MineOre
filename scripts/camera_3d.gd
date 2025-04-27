extends Camera3D

var player = null
var base_offset = Vector3(0, 18, 13)
var offset = base_offset
var smooth_speed = 5.0
var zoom_speed = 2.0
var min_zoom = 5.0
var max_zoom = 25.0

func set_player(player_node):
	player = player_node

func _ready():
	pass

func _input(_event):
	if Input.is_action_just_pressed("zoom_in"):
		zoom(-zoom_speed)
	elif Input.is_action_just_pressed("zoom_out"):
		zoom(zoom_speed)

func _process(delta):
	if player == null:
		return
	
	var target_position = player.global_position + offset
	global_position = global_position.lerp(target_position, delta * smooth_speed)
	look_at(player.global_position, Vector3.UP)

func zoom(amount):
	var distance = offset.length()
	distance += amount
	distance = clamp(distance, min_zoom, max_zoom)
	offset = offset.normalized() * distance
