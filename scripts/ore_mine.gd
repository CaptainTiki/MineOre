extends StaticBody3D

var stored_ore = 0
var gather_rate = 5.0
var gather_timer = 0.0
var health = 5
@onready var ore_detection = $OreDetection
@onready var collection_area = $CollectionArea
@onready var ui_panel = $UILayer/UIPanel
@onready var ore_label = $UILayer/UIPanel/OreLabel
@onready var camera = get_tree().get_root().get_node("Level/Camera")

func _ready():
	collection_area.body_entered.connect(_on_body_entered)
	collection_area.body_exited.connect(_on_body_exited)
	ui_panel.visible = false

func _process(delta):
	if not ore_detection or not camera:
		return
	gather_timer -= delta
	if gather_timer <= 0:
		var ores = ore_detection.get_overlapping_bodies()
		if ores.size() > 0:
			stored_ore += 1
			print("Mine gathered! Stored: ", stored_ore)
			update_ui()
			gather_timer = gather_rate
	if ui_panel.visible:
		var screen_pos = camera.unproject_position(global_position + Vector3(0, 2, 0))
		ui_panel.position = screen_pos - (ui_panel.size / 2)  # Center it

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

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()
	print("Mine health: ", health)

func _on_body_entered(body):
	if body.is_in_group("player"):
		ui_panel.visible = true
		update_ui()

func _on_body_exited(body):
	if body.is_in_group("player"):
		ui_panel.visible = false

func update_ui():
	ore_label.text = "Ore: %d\nPress E" % stored_ore
