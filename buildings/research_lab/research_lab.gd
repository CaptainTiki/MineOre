# res://buildings/research_lab/research_lab.gd
extends Building

@onready var research_label = $UILayer/ResearchPanel/VBoxContainer/ResearchLabel
@onready var research_grid = $UILayer/ResearchPanel/VBoxContainer/ResearchGrid
@onready var hint_label = $UILayer/HintLabel
@onready var hq = get_tree().get_first_node_in_group("headquarters")

var is_menu_open = false

func _ready():
	super._ready()
	add_to_group("research")
	if hint_label:
		hint_label.visible = false
	var panel = get_ui_panel()
	if panel:
		panel.visible = false
		print("ResearchPanel initial visibility set to false")
	else:
		push_error("ResearchPanel not found at UILayer/ResearchPanel")
	print("Research Lab initialized at %s, health: %.2f" % [global_position, health])

func _process(delta):
	var panel = get_ui_panel()
	if panel and panel.visible and camera and is_menu_open:
		var building_top = global_position + Vector3(0, 2.5, 0)  # Adjusted height
		var screen_pos = camera.unproject_position(building_top)
		screen_pos.x -= panel.size.x / 2  # Center horizontally
		screen_pos.y -= panel.size.y      # Align bottom above building
		panel.position = screen_pos
		print("ResearchPanel position: ", panel.position)
	if hint_label and hint_label.visible and camera:
		var screen_pos = camera.unproject_position(global_position + Vector3(0, 2, 0))
		screen_pos.x -= hint_label.size.x / 2
		screen_pos.y -= hint_label.size.y / 2
		hint_label.position = screen_pos

func _on_interact():
	if is_placed and player:
		var bodies = interact_area.get_overlapping_bodies()
		if player in bodies:
			is_menu_open = not is_menu_open
			var panel = get_ui_panel()
			if panel:
				panel.visible = is_menu_open
				print("ResearchPanel visibility set to ", is_menu_open)
				if is_menu_open:
					update_ui()
			else:
				push_error("ResearchPanel not found during interaction")
			print("Research menu %s at %s" % ["opened" if is_menu_open else "closed", global_position])

func _on_body_entered(body):
	if body.is_in_group("player") and is_placed and not player.is_placing:
		if hint_label:
			hint_label.visible = true
		update_ui()

func _on_body_exited(body):
	if body.is_in_group("player"):
		if hint_label:
			hint_label.visible = false
		var panel = get_ui_panel()
		if panel:
			panel.visible = false
			is_menu_open = false
			print("ResearchPanel hidden on body exit")

func update_ui():
	if hint_label:
		hint_label.text = "Press F to open research menu"
	if research_label and research_grid and is_menu_open:
		research_label.text = "Research Options"
		research_grid.get_children().map(func(c): c.queue_free())
		var options = BuildingsManager.research_options
		print("Populating research grid with options: ", options)
		for building in options:
			if building not in BuildingsManager.unlocked_buildings:
				var button = Button.new()
				button.text = "Research %s (%d ore)" % [BuildingsManager.get_building_resource(building).display_name, options[building]["ore_cost"]]
				button.pressed.connect(_on_research_pressed.bind(building))
				research_grid.add_child(button)
				print("Added research button for %s" % building)

func _on_research_pressed(building: String):
	if hq:
		var cost = BuildingsManager.research_options[building]["ore_cost"]
		var withdrawn = hq.withdraw_ore(cost)
		if withdrawn == cost:
			BuildingsManager.research_building(building)
			update_ui()
			print("Researched %s for %d ore" % [building, cost])
		else:
			print("Not enough ore! Need %d, got %d" % [cost, withdrawn])
	else:
		print("Error: No HQ found!")

func _on_destroyed():
	super._on_destroyed()
	print("Research Lab at %s destroyed" % global_position)

func get_ui_panel():
	return $UILayer/ResearchPanel
