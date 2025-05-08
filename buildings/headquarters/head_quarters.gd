# res://buildings/headquarters/head_quarters.gd
extends Building

signal hq_destroyed
signal ore_deposited(amount: int)

var stored_ore = 0
var base_max_ore = 20
var max_ore = base_max_ore
var silo_count = 0

@onready var deposit_label = $UILayer/UIPanel/DepositLabel

func _ready():
	super._ready()
	if interact_area:
		interact_area.monitoring = true
		interact_area.monitorable = true
	if ui_container:
		ui_container.visible = false
	health_changed.connect(_on_health_changed)
	update_ui()

func _on_interact():
	if player and player.carried_ore > 0:
		var space_left = max_ore - stored_ore
		var to_deposit = min(player.carried_ore, space_left)
		if to_deposit > 0:
			stored_ore += to_deposit
			player.carried_ore -= to_deposit
			emit_signal("ore_deposited", to_deposit)
			update_ui()
			print("Deposited %d ore to HQ. Stored: %d/%d" % [to_deposit, stored_ore, max_ore])

func _on_health_changed(_health: float, _max_health: float):
	update_ui()

func update_ui():
	if deposit_label:
		var health_percent = (health / max_health * 100)
		deposit_label.text = "Ore: %d/%d\nHealth: %.0f%%" % [stored_ore, max_ore, health_percent]
	super.update_ui()

func take_damage(amount):
	super.take_damage(amount)
	if health <= 0:
		emit_signal("hq_destroyed")

func deposit_ore(amount):
	var space_left = max_ore - stored_ore
	var to_deposit = min(amount, space_left)
	stored_ore += to_deposit
	update_ui()
	return to_deposit

func withdraw_ore(amount) -> int:
	var to_withdraw = min(amount, stored_ore)
	stored_ore -= to_withdraw
	update_ui()
	return to_withdraw

func add_silo():
	silo_count += 1
	max_ore = base_max_ore + (silo_count * 20)
	update_ui()

func remove_silo():
	if silo_count > 0:
		silo_count -= 1
		max_ore = base_max_ore + (silo_count * 20)
		if stored_ore > max_ore:
			stored_ore = max_ore
		update_ui()
