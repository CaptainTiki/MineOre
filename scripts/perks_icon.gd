extends Control

signal icon_pressed(perk)
signal icon_hovered(perk)
signal icon_unhovered

@onready var texture_button = $MarginContainer/TextureButton

var perk_name: String = ""

func _ready():
	texture_button.pressed.connect(_on_button_pressed)
	texture_button.mouse_entered.connect(_on_mouse_entered)
	texture_button.mouse_exited.connect(_on_mouse_exited)

func set_perk(perk: String):
	perk_name = perk

func set_selected(is_selected: bool):
	if texture_button:
		if is_selected:
			texture_button.modulate = Color(0, 1, 0)  # Green for selected
		else:
			texture_button.modulate = Color(1, 1, 1)  # White for unselected

func _on_button_pressed():
	if perk_name:
		emit_signal("icon_pressed", perk_name)

func _on_mouse_entered():
	if perk_name:
		emit_signal("icon_hovered", perk_name)

func _on_mouse_exited():
	emit_signal("icon_unhovered")
