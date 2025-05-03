# res://scripts/building.gd
class_name Building extends StaticBody3D

signal placed(building_name: String, position: Vector3)
signal destroyed(building_name: String)
signal under_attack(building_name: String)

@export var resource: BuildingResource
@export var grid_extents: Vector2i

var health: float
var is_placed: bool = false  # Tracks if the building is placed
var targeted_by: Array[Node] = []  # Array to track enemies targeting this building
var is_constructed: bool = false
var construction_timer: Timer
var construction_materials: Array = []

@onready var interact_area = get_node_or_null("InteractArea")
@onready var ui_panel = get_node_or_null("UILayer/UIPanel")  # Optional UI panel
@onready var camera = get_tree().get_root().get_node_or_null("Level/Camera")
@onready var player = get_tree().get_root().get_node_or_null("Level/Player")
@onready var mesh_instance = get_node("MeshInstance3D")  # Adjust if path varies

func _init():
	add_to_group("buildings")
	if resource and resource.building_name:
		add_to_group(resource.building_name)

func _ready():
	if resource:
		# Compute grid_extents from collider if not set
		if grid_extents == Vector2i.ZERO:
			var collision_shape = get_node_or_null("CollisionShape3D")
			if collision_shape and collision_shape.shape is BoxShape3D:
				var size = collision_shape.shape.size
				grid_extents = Vector2i(ceil(size.x / 2.0) * 2, ceil(size.z / 2.0) * 2)
		health = PerksManager.get_modified_stat(resource.base_health, "building_health")
	else:
		push_error("Building %s has no resource assigned" % resource.building_name)
	
	# Setup interaction, disabled for non-HQ until placed
	if interact_area and player:
		player.interact.connect(_on_player_interact)
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)
		if ui_panel:
			ui_panel.visible = false
		# Disable interactions for non-HQ buildings until placed
		if resource and resource.building_name != "headquarters":
			interact_area.monitoring = false
			interact_area.monitorable = false
			if ui_panel:
				ui_panel.hide()

func _process(_delta: float):
	# Update UI panel position if visible
	if ui_panel and ui_panel.visible and camera:
		var screen_pos = camera.unproject_position(global_position + Vector3(0, 2, 0))
		ui_panel.position = screen_pos - (ui_panel.size / 2)

func _on_player_interact():
	if interact_area and player and is_placed:
		var bodies = interact_area.get_overlapping_bodies()
		if player in bodies:
			_on_interact()

func _on_interact():
	# Virtual function for derived classes to override
	pass

func _on_body_entered(body):
	if body.is_in_group("player") and ui_panel and is_placed and not player.is_placing:
		ui_panel.visible = true
		update_ui()

func _on_body_exited(body):
	if body.is_in_group("player") and ui_panel:
		ui_panel.visible = false

func update_ui():
	# Virtual function for derived classes to override
	pass

func on_placed():
	is_placed = true
	if resource and resource.building_name != "headquarters" and interact_area:
		interact_area.monitoring = true
		interact_area.monitorable = true
	emit_signal("placed", resource.building_name if resource else name, global_position)

func take_damage(amount: float):
	if amount > 0:
		health -= amount
		emit_signal("under_attack", resource.building_name)
		if health <= 0:
			print(str(resource.building_name) + " destroyed!")
			_on_destroyed()

func can_upgrade() -> bool:
	if not resource or not resource.upgrade_to or resource.upgrade_cost <= 0:
		return false
	var hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")
	return hq and hq.stored_ore >= resource.upgrade_cost

# Virtual function to get the UI panel, overridden by derived classes
func get_ui_panel():
	return get_node_or_null("UILayer/UIPanel")

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

# Targeting management methods
func add_targeting_enemy(enemy: Node):
	if not targeted_by.has(enemy):
		targeted_by.append(enemy)

func remove_targeting_enemy(enemy: Node):
	targeted_by.erase(enemy)
