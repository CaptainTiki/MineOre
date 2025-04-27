# res://buildings/launch_pad/launch_pad.gd
extends Building

signal launch_started
signal launch_completed
signal launch_failed

@onready var hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")
@onready var ui_label = $UILayer/LaunchLabel

var launch_ore_required = 30
var launch_duration = 10.0
var is_launching = false
var launch_timer = 0.0

func _ready():
	super._ready()
	add_to_group("launch_pad")
	print("Launch Pad initialized at %s, health: %.2f" % [global_position, health])

func _process(delta):
	if is_launching:
		launch_timer -= delta
		if launch_timer <= 0:
			complete_launch()
		update_ui()
	super._process(delta)  # Call base class for UI positioning

func _on_interact():
	if is_launching or not hq:
		return
	if hq.stored_ore >= launch_ore_required:
		is_launching = true
		launch_timer = launch_duration
		hq.withdraw_ore(launch_ore_required)
		emit_signal("launch_started")
		if ui_label:
			ui_label.visible = true
		print("Launch started! Countdown: %.1f" % launch_duration)
	else:
		print("Not enough ore for launch: need %d, have %d" % [launch_ore_required, hq.stored_ore])

func complete_launch():
	if not is_launching:
		return
	is_launching = false
	emit_signal("launch_completed")
	if ui_label:
		ui_label.visible = false
	print("Launch completed! Level won!")

func update_ui():
	if ui_label:
		ui_label.text = "Launching: %.1fs" % launch_timer

func _on_destroyed():
	if is_launching:
		emit_signal("launch_failed")
		is_launching = false
	if ui_label:
		ui_label.visible = false
	super._on_destroyed()
	print("Launch Pad at %s destroyed" % global_position)
