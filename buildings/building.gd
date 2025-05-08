# res://scripts/building.gd
class_name Building extends StaticBody3D

signal destroyed(building_name: String)
signal under_attack(building_name: String)
signal health_changed(health: float, max_health: float)
signal placed(building_name: String, position: Vector3)

@export var resource: BuildingResource
@export var grid_extents: Vector2i

var health: float
var max_health: float
var is_placed: bool = false
var targeted_by: Array[Node] = []
var is_constructed: bool = false
var construction_timer: Timer
var construction_materials: Array = []

@onready var interact_area: Area3D = $InteractArea
@onready var health_bar: ProgressBar = $UILayer/HealthBar
@onready var ui_container: Panel = $UILayer/UIPanel

@onready var camera = get_tree().get_root().get_node_or_null("Level/Camera")
@onready var player = get_tree().get_root().get_node_or_null("Level/Player")

func _init():
	add_to_group("buildings")
	if resource and resource.building_name:
		add_to_group(resource.building_name)

func _ready():
	if resource:
		max_health = PerksManager.get_modified_stat(resource.base_health, "building_health")
		health = max_health
		if grid_extents == Vector2i.ZERO:
			var collision_shape = get_node_or_null("CollisionShape3D")
			if collision_shape and collision_shape.shape is BoxShape3D:
				var size = collision_shape.shape.size
				grid_extents = Vector2i(ceil(size.x / 2.0) * 2, ceil(size.z / 2.0) * 2)
	else:
		push_error("Building %s has no resource assigned" % (resource.building_name if resource else "null"))
	
	if interact_area and player:
		player.interact.connect(_on_player_interact)
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)
		if ui_container:
			ui_container.visible = false
		if resource and resource.building_name != "headquarters":
			interact_area.monitoring = false
			interact_area.monitorable = false
			if ui_container:
				ui_container.hide()
	
	if health_bar:
		health_bar.visible = health < max_health
		health_bar.set_process(health < max_health)
		update_health_bar()
	
	if resource and resource.building_name == "headquarters":
		if not placed.is_connected(LevelManager._on_hq_placed):
			placed.connect(LevelManager._on_hq_placed)
		if not destroyed.is_connected(LevelManager._on_building_destroyed):
			destroyed.connect(LevelManager._on_building_destroyed)

func _process(_delta: float):
	if health_bar and health_bar.visible and camera:
		var screen_pos = camera.unproject_position(global_position + Vector3(0, 2, 0))
		health_bar.position = screen_pos - Vector2(health_bar.size.x / 2, health_bar.size.y)
	if ui_container and ui_container.visible and camera:
		var screen_pos = camera.unproject_position(global_position + Vector3(0, 2.5, 0))
		ui_container.position = screen_pos - Vector2(ui_container.size.x / 2, ui_container.size.y)

func _on_player_interact():
	if interact_area and player and is_placed:
		var bodies = interact_area.get_overlapping_bodies()
		if player in bodies:
			_on_interact()

func _on_interact():
	pass

func _on_body_entered(body):
	if body.is_in_group("player"):
		if not player:
			return
		if ui_container and is_placed and not BuildingsManager.is_placing_bldg():
			ui_container.visible = true
			update_ui()

func _on_body_exited(body):
	if body.is_in_group("player"):
		if ui_container:
			ui_container.visible = false

func update_ui():
	if health_bar:
		update_health_bar()

func update_health_bar():
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = health < max_health
		health_bar.set_process(health < max_health)

func on_placed():
	is_placed = true
	if resource and resource.building_name != "headquarters" and interact_area:
		interact_area.monitoring = true
		interact_area.monitorable = true
	BuildingsManager.register_building_placed(self)
	emit_signal("health_changed", health, max_health)
	if resource and resource.building_name == "headquarters":
		emit_signal("placed", resource.building_name, global_position)
		print("HQ placed, emitted placed signal")

func take_damage(amount: float):
	print("building damaged " + str(amount))
	print("health left: " + str(health - amount))
	if amount > 0:
		health = max(0, health - amount)
		emit_signal("under_attack", resource.building_name)
		emit_signal("health_changed", health, max_health)
		update_ui()
		if health <= 0:
			print(str(resource.building_name) + " destroyed!")
			_on_destroyed()

func repair(amount: float):
	if amount > 0:
		health = min(max_health, health + amount)
		emit_signal("health_changed", health, max_health)
		update_ui()

func can_upgrade() -> bool:
	if not resource or not resource.upgrade_to or resource.upgrade_cost <= 0:
		return false
	var hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")
	return hq and hq.stored_ore >= resource.upgrade_cost

func get_ui_panel():
	return get_node_or_null("UILayer/VBoxContainer/UIPanel")

func upgrade():
	if can_upgrade():
		var new_building = load(resource.upgrade_to.scene_path).instantiate()
		new_building.resource = resource.upgrade_to
		new_building.global_position = global_position
		var level = get_tree().get_root().get_node("Level")
		var buildings_node = level.get_node_or_null("Buildings")
		if buildings_node:
			buildings_node.add_child(new_building)
			new_building.owner = level
			var hq = level.get_node_or_null("Buildings/HeadQuarters")
			if hq:
				hq.withdraw_ore(resource.upgrade_cost)
			queue_free()

func _on_destroyed():
	emit_signal("destroyed", resource.building_name)
	queue_free()

func add_targeting_enemy(enemy: Node):
	if not targeted_by.has(enemy):
		targeted_by.append(enemy)

func remove_targeting_enemy(enemy: Node):
	targeted_by.erase(enemy)
