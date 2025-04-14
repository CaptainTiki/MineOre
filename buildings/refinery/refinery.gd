# res://buildings/refinery/refinery.gd
extends Building

signal refined_ore_produced(amount: int)

@onready var interact_area = $InteractArea
@onready var refinery_panel = $UILayer/RefineryPanel
@onready var refinery_label = $UILayer/RefineryPanel/VBoxContainer/RefineryLabel
@onready var refinery_grid = $UILayer/RefineryPanel/VBoxContainer/RefineryGrid
@onready var camera = get_tree().get_root().get_node_or_null("Level/Camera")
@onready var hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")

var refining_options = {
	"basic_refine": {"ore_cost": 2, "refined_ore": 1, "time": 5.0}
}
var is_refining = false
var refine_timer = 0.0
var current_recipe = ""

func _ready():
	super._ready()
	add_to_group("refineries")
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	refinery_panel.visible = false
	update_ui()
	print("Refinery initialized at %s" % global_position)

func _process(delta):
	if is_refining:
		refine_timer -= delta
		if refine_timer <= 0:
			complete_refining()
	if refinery_panel.visible and camera:
		var screen_pos = camera.unproject_position(global_position + Vector3(0, 2, 0))
		refinery_panel.position = screen_pos - (refinery_panel.size / 2)

func _on_body_entered(body):
	if body.is_in_group("player"):
		refinery_panel.visible = true
		update_ui()

func _on_body_exited(body):
	if body.is_in_group("player"):
		refinery_panel.visible = false

func update_ui():
	refinery_label.text = "Refinery Options"
	refinery_grid.get_children().map(func(c): c.queue_free())
	for recipe in refining_options:
		var button = Button.new()
		var opt = refining_options[recipe]
		button.text = "Refine: %d ore → %d refined ore (%ds)" % [opt.ore_cost, opt.refined_ore, opt.time]
		button.disabled = is_refining
		button.pressed.connect(_on_refine_pressed.bind(recipe))
		refinery_grid.add_child(button)

func _on_refine_pressed(recipe: String):
	if is_refining or not hq:
		return
	var opt = refining_options[recipe]
	var withdrawn = hq.withdraw_ore(opt.ore_cost)
	if withdrawn == opt.ore_cost:
		is_refining = true
		refine_timer = opt.time
		current_recipe = recipe
		print("Refinery started: %s, cost %d ore" % [recipe, opt.ore_cost])
	else:
		print("Not enough ore! Need %d, got %d" % [opt.ore_cost, withdrawn])

func complete_refining():
	if not hq:
		is_refining = false
		return
	var opt = refining_options[current_recipe]
	var refined_ore = opt.refined_ore
	hq.deposit_refined_ore(refined_ore)
	emit_signal("refined_ore_produced", refined_ore)
	is_refining = false
	current_recipe = ""
	update_ui()
	print("Refinery produced %d refined ore" % refined_ore)

func _on_destroyed():
	super._on_destroyed()
	is_refining = false
	print("Refinery at %s destroyed" % global_position)
