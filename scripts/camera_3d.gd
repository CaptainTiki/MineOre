extends Camera3D

var player = null
var base_offset = Vector3(0, 15, 10)  # Initial offset for 3/4 view
var offset = base_offset  # Current offset, persists after orbiting
var smooth_speed = 5.0
var is_orbiting = false
var yaw = 0.0
var pitch = -0.785
var orbit_sensitivity = 0.005
var zoom_speed = 2.0
var min_zoom = 5.0
var max_zoom = 20.0

func set_player(player_node):
	player = player_node

func _ready():
	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				var current_offset = global_position - player.global_position
				var distance = current_offset.length()
				var flat_offset = Vector3(current_offset.x, 0, current_offset.z).normalized()
				yaw = atan2(flat_offset.x, flat_offset.z)
				pitch = asin(current_offset.y / distance)
				is_orbiting = true
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				is_orbiting = false
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom(zoom_speed)
	if event is InputEventMouseMotion and is_orbiting:
		yaw -= event.relative.x * orbit_sensitivity
		pitch -= event.relative.y * orbit_sensitivity
		pitch = clamp(pitch, -0.785, PI / 2)
		var distance = offset.length()
		offset = Vector3(
			sin(yaw) * cos(pitch),
			sin(pitch),
			cos(yaw) * cos(pitch)
		).normalized() * distance
		
	if Input.is_action_just_pressed("reset_camera"):
		offset = base_offset

func _process(delta):
	if player == null:
		return
	
	# No reset to base_offset; offset persists after orbiting
	var target_position = player.global_position + offset
	global_position = global_position.lerp(target_position, delta * smooth_speed)
	look_at(player.global_position, Vector3.UP)

func zoom(amount):
	var distance = offset.length()
	distance += amount
	distance = clamp(distance, min_zoom, max_zoom)
	offset = offset.normalized() * distance
