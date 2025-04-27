# res://buildings/headquarters/headquarters.gd
extends Building

signal hq_destroyed
signal health_changed(health)

var stored_ore = 0
var base_max_ore = 20
var max_ore = base_max_ore
var silo_count = 0

@onready var deposit_label = $UILayer/UIPanel/DepositLabel

func _ready():
	super._ready()
	is_placed = true  # HQ is always interactive
	if interact_area:
		interact_area.monitoring = true
		interact_area.monitorable = true
	var panel = get_ui_panel()
	if panel:
		panel.visible = false  # Will show when player enters
	update_ui()
	emit_signal("health_changed", health)

func _on_interact():
	if player and player.carried_ore > 0:
		var space_left = max_ore - stored_ore
		var to_deposit = min(player.carried_ore, space_left)
		if to_deposit > 0:
			stored_ore += to_deposit
			player.carried_ore -= to_deposit
			player.emit_signal("ore_deposited", to_deposit)
			update_ui()
			print("Deposited %d ore to HQ. Stored: %d/%d" % [to_deposit, stored_ore, max_ore])

func update_ui():
	if deposit_label:
		deposit_label.text = "Ore: %d/%d\nPress F" % [stored_ore, max_ore]

func take_damage(amount):
	super.take_damage(amount)
	emit_signal("health_changed", health)
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
