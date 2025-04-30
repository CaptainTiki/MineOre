# res://buildings/ore_mine/ore_mine.gd
extends Building
class_name Ore_Mine

signal ore_produced(amount: int)

var base_ore_per_day = 5  # Base ore produced at day start
var stored_ore = 0
var is_active = true
var is_player_in_interact_area = false

@onready var collection_area = $CollectionArea
@onready var ore_label = $UILayer/UIPanel/OreLabel
@onready var ui_layer = $UILayer
@onready var smoke_effect = $SmokeEffect
@onready var ore_detection = $OreDetection
@onready var hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")
@onready var level = get_tree().get_root().get_node_or_null("Level")
@onready var animation_player = $AnimationPlayer  # Optional

func _ready():
	super._ready()
	add_to_group("ore_mines")
	if level:
		level.connect("start_day", _on_start_day)
	collection_area.connect("body_entered", _on_collection_area_entered)
	collection_area.connect("body_exited", _on_collection_area_exited)
	ui_layer.visible = false
	smoke_effect.emitting = false
	print("Ore Mine initialized at %s" % global_position)

func _process(delta):
	if not is_active or not is_placed or not level:
		return
	# Toggle smoke effect based on day/night
	if level.current_state == level.State.DAY:
		smoke_effect.emitting = true
	else:
		smoke_effect.emitting = false
	super._process(delta)  # Call base class for UI positioning

func _on_start_day():
	if not is_active or not is_placed or not hq or level.current_state != level.State.DAY:
		return
	# Produce base ore + bonus for nearby ore nodes
	var ore_nodes = ore_detection.get_overlapping_bodies().filter(func(body): return body.is_in_group("ores"))
	var bonus_ore = ore_nodes.size()
	var total_ore = base_ore_per_day + bonus_ore
	stored_ore += total_ore
	emit_signal("ore_produced", total_ore)
	print("Ore Mine at %s produced %d ore (%d base + %d bonus)" % [global_position, total_ore, base_ore_per_day, bonus_ore])
	if animation_player and animation_player.has_animation("produce"):
		animation_player.play("produce")
	update_ui()

func _on_collection_area_entered(body):
	if body.is_in_group("player"):
		player = body
		player.connect("interact", _on_interact)
		is_player_in_interact_area = true
		ui_layer.visible = true
		update_ui()

func _on_collection_area_exited(body):
	if body.is_in_group("player"):
		player.disconnect("interact", _on_interact)
		player = null
		is_player_in_interact_area = false
		ui_layer.visible = false

func _on_interact():
	if is_placed and player and is_player_in_interact_area and player.carried_ore < player.carry_capacity:
		var amount = min(stored_ore, player.carry_capacity - player.carried_ore)
		if amount > 0:
			stored_ore -= amount
			player.carried_ore += amount
			player.emit_signal("ore_carried", amount)
			print("Collected %d ore from mine at %s. Remaining: %d" % [amount, global_position, stored_ore])
			update_ui()

func update_ui():
	if ore_label:
		ore_label.text = "Ore: %d\nPress F" % stored_ore

func _on_destroyed():
	is_active = false
	smoke_effect.emitting = false
	ui_layer.visible = false
	super._on_destroyed()
