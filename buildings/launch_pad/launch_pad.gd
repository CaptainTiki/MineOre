# res://buildings/launch_pad/launch_pad.gd
extends Building

signal launch_started
signal launch_completed
signal launch_failed

@onready var hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")
@onready var ui_panel = $UILayer/LaunchPanel
@onready var launch_label = $UILayer/LaunchPanel/VBoxContainer/LaunchLabel


var launch_ore_required = 100  # Hardcoded goal for now
var launch_duration = 10.0
var is_launching = false
var launch_timer = 0.0

func _ready():
	super._ready()
	add_to_group("launch_pad")
	if ui_panel:
		ui_panel.visible = false
	if interact_area:
		interact_area.monitoring = true
		interact_area.monitorable = true
	update_ui()
	print("Launch Pad initialized at %s, health: %.2f" % [global_position, health])

func _process(delta):
	if is_launching:
		launch_timer -= delta
		if launch_timer <= 0:
			complete_launch()
		update_ui()
	super._process(delta)  # Handle UI positioning

func _on_interact():
	if is_launching or not hq:
		return
	if ui_panel:
		ui_panel.visible = !ui_panel.visible
		update_ui()
		if ui_panel.visible:
			print("Launch Pad UI opened at %s" % global_position)

func _on_launch_button_pressed():
	if is_launching or not hq or hq.stored_ore < launch_ore_required:
		return
	is_launching = true
	launch_timer = launch_duration
	hq.withdraw_ore(launch_ore_required)
	emit_signal("launch_started")
	LevelManager.start_night_func()  # Trigger enemy wave
	update_ui()
	print("Launch started! Countdown: %.1f" % launch_duration)

func complete_launch():
	if not is_launching:
		return
	is_launching = false
	emit_signal("launch_completed")
	if ui_panel:
		ui_panel.visible = false
	print("Launch completed! Level won!")

func update_ui():
	if not hq or not launch_label:
		return
	var ore_status = hq.stored_ore if hq else 0
	launch_label.text = "Ore: %d/%d" % [ore_status, launch_ore_required]
	if is_launching:
		launch_label.text += "\nLaunching: %.1fs" % launch_timer
	super.update_ui()

func _on_destroyed():
	if is_launching:
		emit_signal("launch_failed")
		is_launching = false
	if ui_panel:
		ui_panel.visible = false
	super._on_destroyed()
	print("Launch Pad at %s destroyed" % global_position)
