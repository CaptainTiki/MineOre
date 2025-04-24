# res://buildings/research_lab/research_lab.gd
extends Building

@onready var interact_area = $InteractArea
@onready var research_panel = $UILayer/ResearchPanel
@onready var research_label = $UILayer/ResearchPanel/VBoxContainer/ResearchLabel
@onready var research_grid = $UILayer/ResearchPanel/VBoxContainer/ResearchGrid
@onready var camera = get_tree().get_root().get_node_or_null("Level/Camera")
@onready var hq = get_tree().get_first_node_in_group("headquarters")

func _ready():
	super._ready()
	add_to_group("research")
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	research_panel.visible = false
	update_ui()
	print("Research Lab initialized at %s, health: %.2f" % [global_position, health])

func _process(_delta):
	if research_panel.visible and camera:
		var screen_pos = camera.unproject_position(global_position + Vector3(0, 2, 0))
		research_panel.position = screen_pos - (research_panel.size / 2)

func _on_body_entered(body):
	if body.is_in_group("player"):
		research_panel.visible = true
		update_ui()

func _on_body_exited(body):
	if body.is_in_group("player"):
		research_panel.visible = false

func update_ui():
	research_label.text = "Research Options"
	research_grid.get_children().map(func(c): c.queue_free())
	var options = BuildingsManager.research_options
	for building in options:
		if building not in BuildingsManager.unlocked_buildings:
			var button = Button.new()
			button.text = "%s (%d ore)" % [BuildingsManager.get_building_resource(building).display_name, options[building]["ore_cost"]]
			button.pressed.connect(_on_research_pressed.bind(building))
			research_grid.add_child(button)

func _on_research_pressed(building: String):
	if hq:
		var cost = BuildingsManager.research_options[building]["ore_cost"]
		var withdrawn = hq.withdraw_ore(cost)
		if withdrawn == cost:
			BuildingsManager.unlock_building(building)
			update_ui()
			print("Researched %s for %d ore" % [building, cost])
		else:
			print("Not enough ore! Need %d, got %d" % [cost, withdrawn])
	else:
		print("Error: No HQ found!")

func _on_destroyed():
	super._on_destroyed()
	research_panel.visible = false
	print("Research Lab at %s destroyed" % global_position)
