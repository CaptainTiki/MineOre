extends Panel

signal building_selected(scene_path, building_name)

@onready var unique_grid = $VBoxContainer/UniqueGrid
@onready var ore_grid = $VBoxContainer/OreGrid
@onready var defenses_grid = $VBoxContainer/DefensesGrid

var placed_uniques = []

func _ready():
	visible = false
	update_menu()
	print("ConstructionMenu ready")

func show_menu():
	visible = true
	get_tree().paused = false
	update_menu()
	print("Construction menu shown")

func hide_menu():
	visible = false
	print("Construction menu hidden")

func update_menu():
	# Clear grids
	for grid in [unique_grid, ore_grid, defenses_grid]:
		grid.get_children().map(func(c): c.queue_free())
	
	# Populate grids
	for building in BuildingUnlocks.building_configs:
		var config = BuildingUnlocks.building_configs[building]
		if BuildingUnlocks.is_building_unlocked(building) or building in ["hq", "research", "ore_mine", "turret"]:
			var button = Button.new()
			button.text = "%s (%d ore)" % [building.capitalize(), config.cost]
			if config.get("unique", false) and building in placed_uniques:
				button.disabled = true
				button.modulate = Color(0.5, 0.5, 0.5)
			button.pressed.connect(_on_building_pressed.bind(config.scene, building))
			match config.category:
				"unique": unique_grid.add_child(button)
				"ore": ore_grid.add_child(button)
				"defenses": defenses_grid.add_child(button)
			print("Added button for ", building)

func mark_unique_placed(building: String):
	if building in BuildingUnlocks.building_configs and BuildingUnlocks.building_configs[building].get("unique", false):
		placed_uniques.append(building)
		update_menu()
		print("Marked ", building, " as placed")

func _on_building_pressed(scene_path: String, building_name: String):
	emit_signal("building_selected", scene_path, building_name)
