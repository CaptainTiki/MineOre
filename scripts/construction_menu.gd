# res://scenes/construction_menu.gd
extends Control

@onready var vbox_container = $VBoxContainer
var placed_uniques = []

func _ready():
	visible = false
	update_menu()

func show_menu():
	visible = true
	update_menu()

func hide_menu():
	visible = false

func update_menu():
	print("Updating menu, configs: ", BuildingsManager.building_configs.keys())
	print("Unlocked buildings: ", BuildingsManager.unlocked_buildings)
	# Clear all children in VBoxContainer
	for child in vbox_container.get_children():
		child.queue_free()
	
	var categories = {}
	for building in BuildingsManager.building_configs:
		var config = BuildingsManager.building_configs[building]
		var resource = BuildingsManager.get_building_resource(building)
		if resource:
			var is_visible = (building in BuildingsManager.unlocked_buildings or not resource.is_researchable) and not resource.is_locked
			print("Building %s: is_researchable=%s, is_locked=%s, visible=%s" % [building, resource.is_researchable, resource.is_locked, is_visible])
			if is_visible:
				var button = Button.new()
				button.text = "%s (%d ore)" % [resource.display_name, config.cost]
				if resource.is_unique and building in placed_uniques:
					button.disabled = true
					button.modulate = Color(0.5, 0.5, 0.5)
				button.pressed.connect(_on_building_pressed.bind(config.scene, building))
				if not categories.has(config.category):
					categories[config.category] = GridContainer.new()
					categories[config.category].name = config.category.capitalize() + "Grid"
					categories[config.category].columns = 2
					var label = Label.new()
					label.text = config.category.capitalize()
					vbox_container.add_child(label)
					vbox_container.add_child(categories[config.category])
				categories[config.category].add_child(button)
		else:
			push_warning("No resource for building: %s" % building)

func _on_building_pressed(scene_path, building_name):
	var player = get_tree().get_root().get_node("Level/Player")
	if player:
		player.start_placement(scene_path, building_name)
	visible = false

func mark_unique_placed(building: String):
	if building in BuildingsManager.building_configs and BuildingsManager.building_configs[building].get("unique", false):
		placed_uniques.append(building)
		update_menu()
