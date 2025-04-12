extends Control

signal icon_pressed(perk)
signal icon_hovered(perk)
signal icon_unhovered

@onready var texture_button = $MarginContainer/TextureButton

var perk_name: String = ""

func _ready():
	if not texture_button:
		print("Error: TextureButton not found in PerksIcon!")
	else:
		texture_button.pressed.connect(_on_button_pressed)
		texture_button.mouse_entered.connect(_on_mouse_entered)
		texture_button.mouse_exited.connect(_on_mouse_exited)
		update_visuals()
		print("PerksIcon ready for perk: ", perk_name)

func set_perk(perk: String):
	perk_name = perk
	if is_node_ready() and texture_button:
		update_visuals()
	else:
		print("Deferring visuals update for ", perk_name, " until ready")

func set_selected(is_selected: bool):
	if texture_button:
		if is_selected:
			texture_button.modulate = Color(0, 1, 0)  # Green for selected
		else:
			texture_button.modulate = Color(1, 1, 1)  # White for unselected
		print("PerksIcon ", perk_name, " set to ", "green" if is_selected else "white", ", modulate: ", texture_button.modulate)
	else:
		print("Warning: Cannot set selected for ", perk_name, " - texture_button null")

func update_visuals():
	if texture_button and perk_name:
		# No tooltip_text to avoid default tooltip
		pass
	else:
		if not texture_button:
			print("Cannot update visuals: texture_button is null")
		if not perk_name:
			print("Cannot update visuals: perk_name is empty")

func _on_button_pressed():
	if perk_name:
		emit_signal("icon_pressed", perk_name)
		print("PerksIcon pressed: ", perk_name)

func _on_mouse_entered():
	if perk_name:
		emit_signal("icon_hovered", perk_name)
		print("PerksIcon hovered: ", perk_name)

func _on_mouse_exited():
	emit_signal("icon_unhovered")
	print("PerksIcon unhovered: ", perk_name)
