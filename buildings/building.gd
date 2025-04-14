# res://scripts/building.gd
class_name Building extends StaticBody3D

signal placed(building_name: String, position: Vector3)
signal destroyed(building_name: String)
signal under_attack(building_name: String)

@export var resource: BuildingResource
var health: float

func _init():
	add_to_group("buildings")
	if resource and resource.name:
		add_to_group(resource.name)

func _ready():
	if resource:
		health = Perks.get_modified_stat(resource.base_health, "building_health")
		emit_signal("placed", resource.name, global_position)
	else:
		push_error("Building %s has no resource assigned" % name)

func take_damage(amount: float):
	if amount > 0:
		health -= amount
		emit_signal("under_attack", resource.name)
		if health <= 0:
			emit_signal("destroyed", resource.name)
			queue_free()

func can_upgrade() -> bool:
	if not resource or not resource.upgrade_to or resource.upgrade_cost <= 0:
		return false
	var hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")
	return hq and hq.stored_ore >= resource.upgrade_cost

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
	emit_signal("destroyed", resource.name if resource else name)
	queue_free()
