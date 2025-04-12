extends StaticBody3D

signal hq_destroyed
signal health_changed(health)

var base_health = 5.0
var health: float

@onready var interact_area = $InteractArea
@onready var ui_panel = $UILayer/UIPanel
@onready var deposit_label = $UILayer/UIPanel/DepositLabel
@onready var camera = get_tree().get_root().get_node("Level/Camera")

func _init():
	health = Perks.get_modified_stat(base_health, "building_health")
	add_to_group("hq")
	add_to_group("buildings")
	print("HQ initialized with: health=", health)

func _ready():
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	ui_panel.visible = false
	update_ui()
	emit_signal("health_changed", health)

func _process(delta):
	if ui_panel.visible and camera:
		var screen_pos = camera.unproject_position(global_position + Vector3(0, 2, 0))
		ui_panel.position = screen_pos - (ui_panel.size / 2)

func take_damage(amount):
	health -= amount
	emit_signal("health_changed", health)
	if health <= 0:
		emit_signal("hq_destroyed")
		queue_free()
	print("HQ health: ", health)

func deposit_ore(amount):
	return amount  # Returns amount deposited for player to subtract

func _on_body_entered(body):
	if body.is_in_group("player"):
		ui_panel.visible = true
		update_ui()

func _on_body_exited(body):
	if body.is_in_group("player"):
		ui_panel.visible = false

func update_ui():
	deposit_label.text = "Deposit\nPress E"
