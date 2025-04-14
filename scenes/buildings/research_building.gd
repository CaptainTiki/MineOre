extends StaticBody3D

var base_health = 5.0
var health: float

@onready var interact_area = $InteractArea
@onready var research_panel = $UILayer/ResearchPanel
@onready var research_label = $UILayer/ResearchPanel/VBoxContainer/ResearchLabel
@onready var research_grid = $UILayer/ResearchPanel/VBoxContainer/ResearchGrid
@onready var camera = get_tree().get_root().get_node("Level/Camera")

func _init():
	health = Perks.get_modified_stat(base_health, "building_health")
	add_to_group("buildings")
	add_to_group("research")
	print("Research Building initialized with: health=", health)

func _ready():
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	research_panel.visible = false
	update_ui()

func _process(delta):
	if research_panel.visible and camera:
		var screen_pos = camera.unproject_position(global_position + Vector3(0, 2, 0))
		research_panel.position = screen_pos - (research_panel.size / 2)

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()
	print("Research Building health: ", health)

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
	var options = BuildingUnlocks.get_research_options()
	print("Updating research menu. Options: ", options.keys())
	for building in options:
		if not BuildingUnlocks.is_building_unlocked(building):
			var button = Button.new()
			button.text = "%s (%d ore)" % [building.capitalize(), options[building]["ore_cost"]]
			button.pressed.connect(_on_research_pressed.bind(building))
			research_grid.add_child(button)
		else:
			print("Skipping research: ", building, " (already unlocked)")

func _on_research_pressed(building: String):
	var hq = get_tree().get_first_node_in_group("hq")
	if hq:
		var cost = BuildingUnlocks.get_ore_cost(building)
		var withdrawn = hq.withdraw_ore(cost)
		if withdrawn == cost:
			BuildingUnlocks.unlock_building(building)
			update_ui()
			print("Researched ", building, " for ", cost, " ore")
		else:
			print("Not enough ore! Need ", cost, ", got ", withdrawn)
	else:
		print("Error: No HQ found!")
