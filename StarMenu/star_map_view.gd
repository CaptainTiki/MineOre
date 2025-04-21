extends Node3D

signal system_selected(system)

var highlighted_system: Node3D = null
var highlight_sprite: Sprite3D = null

@onready var system_name_label = $UI/SystemInfoPanel/InfoContainer/SystemNameLabel
@onready var difficulty_label = $UI/SystemInfoPanel/InfoContainer/DifficultyLabel
@onready var progress_label = $UI/SystemInfoPanel/InfoContainer/ProgressLabel
@onready var description_label = $UI/SystemInfoPanel/InfoContainer/DescriptionLabel
@onready var locked_label = $UI/SystemInfoPanel/InfoContainer/LockedLabel

func _ready():
	# Initialize highlight sprite
	highlight_sprite = Sprite3D.new()
	highlight_sprite.texture = preload("res://assets/ring.png") # Placeholder; replace with your texture
	highlight_sprite.scale = Vector3(3.0, 3.0, 3.0) # Adjust size
	highlight_sprite.translate(Vector3(0, 0.5, 0)) # Slightly above star
	highlight_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	highlight_sprite.visible = false
	add_child(highlight_sprite)

func set_systems(systems_node: Node3D):
	for system in systems_node.get_children():
		if system is Node3D and system.has_signal("clicked"):
			system.connect("clicked", _on_system_clicked)
			# Connect mouse enter/exit signals
			system.connect("mouse_entered", _on_system_mouse_entered.bind(system))
			system.connect("mouse_exited", _on_system_mouse_exited.bind(system))
	
	# Start animation after systems are ready
	call_deferred("_start_animation", systems_node)

func _on_system_clicked(resource: StarSystemResource):
	emit_signal("system_selected", resource)

func _start_animation(systems_node: Node3D):
	# Collect and sort systems by y-position (top to bottom)
	var systems = systems_node.get_children()
	systems.sort_custom(func(a, b): return a.position.y > b.position.y)
	
	# Play animation for each system with staggered delay
	var delay_per_system = 0.15
	for i in systems.size():
		await get_tree().create_timer(delay_per_system).timeout
		var system = systems[i]
		system.visible = false
		# Play animation with delay
		system.play_anim("blink_on_animation")

func _on_system_mouse_entered(system: Node3D):
	if system.resource:
		highlighted_system = system
		update_ui(system.resource)
		# Show highlight sprite
		highlight_sprite.visible = true
		highlight_sprite.global_transform.origin = system.global_transform.origin + Vector3(0, 0.5, 0)

func _on_system_mouse_exited(system: Node3D):
	if highlighted_system == system:
		highlighted_system = null
		clear_ui()
		highlight_sprite.visible = false

func update_ui(resource: StarSystemResource):
	system_name_label.text = resource.system_name
	difficulty_label.text = "Difficulty: %d" % resource.difficulty
	progress_label.text = "Progress: 0 / %d" % resource.planets.size()
	description_label.text = "Description: %s" % resource.description
	locked_label.text = "Locked: %s" % ("Yes" if resource.locked else "No")

func clear_ui():
	system_name_label.text = "Select a system"
	difficulty_label.text = "Difficulty: -"
	progress_label.text = "Progress: -"
	description_label.text = "Description: -"
	locked_label.text = "Locked: -"
