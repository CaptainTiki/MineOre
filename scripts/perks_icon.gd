extends Control

signal icon_pressed(perk_name)
signal icon_hovered(perk_name)
signal icon_unhovered

@onready var texture_button = $CenterContainer/TextureButton

var perk_name = ""
var normal_size = Vector2(48, 48)
var highlight_size = Vector2(64, 64)

func _ready():
	# Ensure initial scale is set explicitly
	texture_button.scale = Vector2(1, 1)
	# Set focus mode to NONE to prevent Godot's default UI interference
	texture_button.focus_mode = Control.FOCUS_NONE
	# enforce pivot on texture button
	texture_button.pivot_offset = Vector2(24,24)

func set_perk(perk: String):
	perk_name = perk

func set_selected(selected: bool):
	if texture_button:
		texture_button.set_pressed(selected)
	else:
		push_warning("TextureButtonrid not ready yet for perk: " + perk_name)

func set_highlight(highlighted: bool):
	# Define target scale: 1.5x for highlight (36/24), 1x for normal
	var target_scale = Vector2(1.5, 1.5) if highlighted else Vector2(1, 1)
	# Create a tween for animation
	var tween = create_tween()
	# Animate scale with elastic transition for overshoot effect
	tween.tween_property(texture_button, "scale", target_scale, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_texture_button_pressed():
	emit_signal("icon_pressed", perk_name)

func _on_texture_button_mouse_entered():
	emit_signal("icon_hovered", perk_name)

func _on_texture_button_mouse_exited():
	emit_signal("icon_unhovered")
