extends Control

signal icon_pressed(perk_name)
signal icon_hovered(perk_name)
signal icon_unhovered

@onready var texture_button = $CenterContainer/TextureButton

var perk: Perk = null
var perk_name: String = ""  # Alias for perk.id, kept for compatibility
var normal_size = Vector2(48, 48)
var highlight_size = Vector2(64, 64)

# Configure the button and set textures if perk is already set
func _ready():
	texture_button.scale = Vector2(1, 1)
	texture_button.focus_mode = Control.FOCUS_NONE
	texture_button.pivot_offset = Vector2(24, 24)
	update_textures()

# Store the perk and update textures only if texture_button is ready
func set_perk(p: Perk):
	perk = p
	perk_name = p.id  # Assuming perk_name is used elsewhere
	if texture_button:  # Check if texture_button is assigned
		update_textures()

# Helper function to set the textures
func update_textures():
	if perk.unlocked:
		var normal_tex = load(perk.normal_icon_path)
		texture_button.texture_normal = normal_tex if normal_tex else load("res://perks/default_normal.png")
		var pressed_tex = load(perk.pressed_icon_path)
		texture_button.texture_pressed = pressed_tex if pressed_tex else load("res://perks/default_pressed.png")
		texture_button.disabled = false
	else:
		texture_button.texture_normal = load("res://perks/defaults/perk_locked_bn.png")
		texture_button.texture_pressed = null
		texture_button.disabled = true

func set_selected(selected: bool):
	if texture_button:
		texture_button.set_pressed(selected)
	else:
		push_warning("TextureButton not ready yet for perk: " + perk_name)

func set_highlight(highlighted: bool):
	var target_scale = Vector2(1.5, 1.5) if highlighted else Vector2(1, 1)
	var tween = create_tween()
	tween.tween_property(texture_button, "scale", target_scale, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_texture_button_pressed():
	emit_signal("icon_pressed", perk_name)

func _on_texture_button_mouse_entered():
	emit_signal("icon_hovered", perk_name)

func _on_texture_button_mouse_exited():
	emit_signal("icon_unhovered")
