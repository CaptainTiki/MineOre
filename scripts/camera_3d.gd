extends Camera3D

var player = null
var offset = Vector3(0, 15, 10)  # Initial offset for 3/4 view
var smooth_speed = 5.0  # How quickly the camera follows

func set_player(player_node):
	player = player_node

func _process(delta):
	if player == null:
		return
	
	# Target position: player's position plus the offset
	var target_position = player.global_position + offset
	
	# Smoothly move toward the target position
	global_position = global_position.lerp(target_position, delta * smooth_speed)
	
	# Always look at the player
	look_at(player.global_position, Vector3.UP)
