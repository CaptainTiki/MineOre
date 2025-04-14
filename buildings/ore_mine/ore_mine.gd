# res://buildings/ore_mine/ore_mine.gd
extends Building

signal ore_produced(amount: int)

var base_production_rate = 10.0 # Seconds per ore
var production_rate: float
var ore_timer: float = 0.0
var is_active = true
var stored_ore = 0

@onready var collection_area: Area3D = $CollectionArea
@onready var ore_label: Label = $UILayer/UIPanel/OreLabel
@onready var ui_panel: Panel = $UILayer/UIPanel
@onready var hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")
@onready var level = get_tree().get_root().get_node_or_null("Level")
@onready var animation_player = $AnimationPlayer # Optional
@onready var camera = get_tree().get_root().get_node("Level/Camera")

func _ready():
	super._ready()
	production_rate = Perks.get_modified_stat(base_production_rate, "mine_rate")
	ore_timer = production_rate
	add_to_group("ore_mines")
	collection_area.body_entered.connect(_on_body_entered)
	collection_area.body_exited.connect(_on_body_exited)
	ui_panel.visible = false
	print("Ore Mine initialized, production_rate: %.2f seconds" % production_rate)

func _process(delta):
	if not is_active or not level or level.current_state in [level.State.WON, level.State.LOST]:
		return
	if hq and hq.is_inside_tree():
		ore_timer -= delta
		if ore_timer <= 0:
			produce_ore()
			ore_timer = production_rate
	else:
		hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")
		if not hq:
			is_active = false
			push_warning("Ore Mine at %s stopped: No HQ found" % global_position)
	if ui_panel.visible:
		var screen_pos = camera.unproject_position(global_position + Vector3(0, 2, 0))
		ui_panel.position = screen_pos - (ui_panel.size / 2)

func produce_ore():
	if hq:
		var ore_produced = 1
		stored_ore += ore_produced
		emit_signal("ore_produced", ore_produced)
		print("Ore Mine produced %d ore" % ore_produced)
		if animation_player and animation_player.has_animation("produce"):
			animation_player.play("produce")
	else:
		push_warning("No HQ found for Ore Mine at %s" % global_position)
	update_ui()

func collect_ore(amount):
	if stored_ore >= amount:
		stored_ore -= amount
		print("Collected from mine! Remaining: ", stored_ore)
		update_ui()
		return amount
	else:
		var collected = stored_ore
		stored_ore = 0
		print("Collected all from mine! Remaining: 0")
		update_ui()
		return collected
	return 0

func _on_body_entered(body):
	if body.is_in_group("player"):
		ui_panel.visible = true
		update_ui()
	else:
		print(body)

func _on_body_exited(body):
	if body.is_in_group("player"):
		ui_panel.visible = false

func _on_destroyed():
	is_active = false
	super._on_destroyed()

func update_ui():
	ore_label.text = "Ore: %d\nPress E" % stored_ore
