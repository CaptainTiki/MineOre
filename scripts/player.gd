# res://scripts/player.gd
extends CharacterBody3D
class_name Player

# Signals for game events
signal ore_carried(amount)
signal interact
signal destroyed

# Tool enumeration and properties
enum Tool { NONE, GUN, MINING_LASER, BUILD_REPAIR }
var current_tool = Tool.NONE
var speed = 5.0
var carry_capacity = 20
var carried_ore = 0
var targeted_by: Array[Node] = []
var rotation_speed = 5.0

# Node references
@onready var camera = get_node_or_null("../Camera")
@onready var gun = $Gun
@onready var mining_laser = $MiningLaser
@onready var build_repair_tool = $BuildRepairTool

func _ready():
	Input.action_release("use_tool")
	add_to_group("player")
	gun.visible = false
	mining_laser.visible = false
	mining_laser.cone.monitoring = false
	build_repair_tool.visible = false
	if not camera:
		camera = get_tree().root.get_node_or_null("Level/Camera")
	if not ore_carried.is_connected(LevelManager._on_ore_carried):
		ore_carried.connect(LevelManager._on_ore_carried)
	print("Player initialized")

func _process(delta: float) -> void:
	if not build_repair_tool.construction_menu.visible:
		if Input.is_action_pressed("use_tool"):
			use_tool(true)
		elif Input.is_action_just_released("use_tool"):
			use_tool(false)
		if Input.is_action_just_pressed("interact"):
			emit_signal("interact")

	if Input.is_action_just_pressed("switch_tool_next"):
		switch_tool_next()
	if Input.is_action_just_pressed("switch_tool_prev"):
		switch_tool_prev()

func _physics_process(delta: float) -> void:
	var input = Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_backward")
	
	velocity = input.normalized() * speed
	velocity += get_gravity()
	move_and_slide()
	
	position.x = clamp(position.x, -50, 50)
	position.z = clamp(position.z, -50, 50)
	
	var is_using_controller = Input.get_joy_name(0) != ""
	if is_using_controller:
		var look_x = Input.get_axis("navigate_left", "navigate_right")
		var look_y = Input.get_axis("navigate_up", "navigate_down")
		if look_x != 0 or look_y != 0:
			var look_dir = Vector3(look_x, 0, look_y).normalized()
			var target_rotation = atan2(look_dir.x, look_dir.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, delta * rotation_speed)
	else:
		if camera:
			var mouse_pos = get_viewport().get_mouse_position()
			var ray_origin = camera.project_ray_origin(mouse_pos)
			var ray_dir = camera.project_ray_normal(mouse_pos)
			var plane = Plane(Vector3.UP, 0)
			var intersect = plane.intersects_ray(ray_origin, ray_dir)
			if intersect:
				var look_pos = intersect
				look_at(Vector3(look_pos.x, global_position.y, look_pos.z), Vector3.UP)

func switch_tool_next():
	var tools = [Tool.NONE, Tool.GUN, Tool.MINING_LASER, Tool.BUILD_REPAIR]
	var current_index = tools.find(current_tool)
	current_index = (current_index + 1) % tools.size()
	switch_tool(tools[current_index])

func switch_tool_prev():
	var tools = [Tool.NONE, Tool.GUN, Tool.MINING_LASER, Tool.BUILD_REPAIR]
	var current_index = tools.find(current_tool)
	current_index = (current_index - 1) % tools.size()
	switch_tool(tools[current_index])

func switch_tool(new_tool: Tool):
	current_tool = new_tool
	gun.visible = (current_tool == Tool.GUN)
	mining_laser.visible = (current_tool == Tool.MINING_LASER)
	mining_laser.cone.monitoring = (current_tool == Tool.MINING_LASER)
	build_repair_tool.visible = (current_tool == Tool.BUILD_REPAIR)

func use_tool(is_pressed: bool):
	match current_tool:
		Tool.GUN:
			gun.use_tool(self, is_pressed)
		Tool.MINING_LASER:
			mining_laser.use_tool(self, is_pressed)
		Tool.BUILD_REPAIR:
			build_repair_tool.use_tool(self, is_pressed)

func add_targeting_enemy(enemy: Node):
	if not targeted_by.has(enemy):
		targeted_by.append(enemy)

func remove_targeting_enemy(enemy: Node):
	targeted_by.erase(enemy)
