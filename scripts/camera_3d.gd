extends Camera3D

var player = null
var base_offset = Vector3(0, 18, 13)  # Higher, less tilted (high-angle top-down)
var offset = base_offset
var smooth_speed = 5.0
var zoom_speed = 2.0
var min_zoom = 5.0
var max_zoom = 25.0  # Increased slightly for higher starting point

func set_player(player_node):
	player = player_node

func _ready():
	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom(zoom_speed)

func _process(delta):
	if player == null:
		return
	
	if Input.is_action_just_pressed("reset_camera"):
		offset = base_offset
	
	var target_position = player.global_position + offset
	global_position = global_position.lerp(target_position, delta * smooth_speed)
	look_at(player.global_position, Vector3.UP)

func zoom(amount):
	var distance = offset.length()
	distance += amount
	distance = clamp(distance, min_zoom, max_zoom)
	offset = offset.normalized() * distance
