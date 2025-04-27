# res://scenes/construction_menu.gd
extends Control

@onready var vbox_container = $VBoxContainer
var placed_uniques = []
var current_button_index = 0
var buttons = []

func _ready():
	visible = false
	update_menu()

func _input(_event):
	if visible:
		if Input.is_action_just_pressed("navigate_down"):
			current_button_index = (current_button_index + 1) % buttons.size()
			update_button_focus()
		elif Input.is_action_just_pressed("navigate_up"):
			current_button_index = (current_button_index - 1) % buttons.size()
			if current_button_index < 0:
				current_button_index = buttons.size() - 1
			update_button_focus()
		elif Input.is_action_just_pressed("select") and buttons.size() > 0:
			var button = buttons[current_button_index]
			if not button.disabled:
				button.emit_signal("pressed")
		elif Input.is_action_just_pressed("cancel"):
			hide_menu()

func show_menu():
	visible = true
	update_menu()
	if buttons.size() > 0:
		current_button_index = 0
		update_button_focus()

func hide_menu():
	visible = false

func update_menu():
	buttons.clear()
	for child in vbox_container.get_children():
		child.queue_free()
	
	var categories = {}
	for building in BuildingsManager.building_configs:
		var config = BuildingsManager.building_configs[building]
		var resource = BuildingsManager.get_building_resource(building)
		if resource:
			var ui_is_visible = (building in BuildingsManager.unlocked_buildings or not resource.is_researchable) and not resource.is_locked
			if ui_is_visible:
				var button = Button.new()
				button.text = "%s (%d ore)" % [resource.display_name, config.cost]
				button.focus_mode = Control.FOCUS_ALL
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
				buttons.append(button)
		else:
			push_warning("No resource for building: %s" % building)

func update_button_focus():
	if buttons.size() > 0:
		buttons[current_button_index].grab_focus()

func _on_building_pressed(scene_path, building_name):
	var player = get_tree().get_root().get_node("Level/Player")
	if player:
		player.start_placement(scene_path, building_name)
	visible = false

func mark_unique_placed(building: String):
	if building in BuildingsManager.building_configs and BuildingsManager.building_configs[building].get("unique", false):
		placed_uniques.append(building)
		update_menu()
