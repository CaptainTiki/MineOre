# res://buildings/ore_mine/ore_mine.gd
extends Building

signal ore_produced(amount: int)

var base_production_rate = 10.0  # Seconds per ore
var production_rate: float
var ore_timer: float = 0.0
var is_active = true
var stored_ore = 0

@onready var collection_area = $CollectionArea
@onready var ore_label = $UILayer/UIPanel/OreLabel
@onready var hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")
@onready var level = get_tree().get_root().get_node_or_null("Level")
@onready var animation_player = $AnimationPlayer  # Optional

func _ready():
	super._ready()
	production_rate = Perks.get_modified_stat(base_production_rate, "mine_rate")
	ore_timer = production_rate
	add_to_group("ore_mines")
	print("Ore Mine initialized, production_rate: %.2f seconds" % production_rate)

func _process(delta):
	if not is_active or not is_placed or not level or level.current_state in [level.State.WON, level.State.LOST]:
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
	super._process(delta)  # Call base class for UI positioning

func produce_ore():
	if hq:
		var produced = 1
		stored_ore += produced
		emit_signal("ore_produced", ore_produced)
		print("Ore Mine produced %d ore" % produced)
		if animation_player and animation_player.has_animation("produce"):
			animation_player.play("produce")
	update_ui()

func _on_interact():
	if is_placed and player and player.carried_ore < player.carry_capacity:
		var amount = min(stored_ore, player.carry_capacity - player.carried_ore)
		if amount > 0:
			stored_ore -= amount
			player.carried_ore += amount
			player.emit_signal("ore_carried", amount)
			print("Collected %d ore from mine. Remaining: %d" % [amount, stored_ore])
			update_ui()

func update_ui():
	if ore_label:
		ore_label.text = "Ore: %d\nPress F" % stored_ore

func _on_destroyed():
	is_active = false
	super._on_destroyed()
