extends StaticBody3D

signal launch_started
signal launch_completed
signal launch_failed

var base_health = 5.0
var health: float
var launch_ore_required = 30
var launch_duration = 10.0
var is_launching = false
var launch_timer = 0.0

func _init():
	health = Perks.get_modified_stat(base_health, "building_health")
	add_to_group("buildings")
	add_to_group("launch_pad")
	print("Launch Pad initialized with: health=", health)

func _ready():
	pass

func _process(delta):
	if is_launching:
		launch_timer -= delta
		if launch_timer <= 0:
			complete_launch()
		update_ui()

func take_damage(amount):
	health -= amount
	if health <= 0:
		emit_signal("launch_failed")
		is_launching = false
		queue_free()
		print("Launch Pad destroyed")
	else:
		print("Launch Pad health: ", health)

func start_launch():
	var hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")
	if hq and hq.stored_ore >= launch_ore_required:
		is_launching = true
		launch_timer = launch_duration
		hq.withdraw_ore(launch_ore_required)
		emit_signal("launch_started")
		print("Launch started! Countdown: ", launch_duration)
	else:
		print("Not enough ore for launch: need ", launch_ore_required)

func complete_launch():
	if is_launching:
		is_launching = false
		emit_signal("launch_completed")
		var game_state = get_node("/root/GameState")
		game_state.complete_planet("Planet1") # Adjust planet name
		print("Launch completed! Level won!")

func update_ui():
	# Placeholder: Add a UI label or 3D text for countdown
	pass
