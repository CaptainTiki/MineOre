extends Panel
class_name PerksScreen

signal perks_selected(perks, planet_data)

@onready var perks_grid = $PerksGrid
@onready var hover_panel = $HoverPanel
@onready var perk_name_label = $HoverPanel/VBoxContainer/PerkNameLabel
@onready var perk_desc_label = $HoverPanel/VBoxContainer/PerkDescLabel
@onready var paper_doll_panel = $PaperDollPanel
@onready var doll_label = $PaperDollPanel/DollLabel
@onready var go_button = $GoButton

var available_perks = ["building_health", "turret_rotation_speed", "turret_damage", "turret_fire_rate", "player_movement_speed"]
var chosen_perks = []
var selected_planet = null

func _ready():
	visible = false
	go_button.pressed.connect(_on_go_pressed)
	doll_label.text = "Paper Doll\n(Coming Soon)"
	hover_panel.visible = false
	
	# Populate perks grid
	for perk in available_perks:
		var button = Button.new()
		button.text = perk.capitalize()
		button.size = Vector2(200, 50)
		button.focus_mode = FOCUS_NONE  # Disable focus outline
		button.mouse_entered.connect(_on_perk_hover.bind(perk))
		button.mouse_exited.connect(_on_perk_hover_exit)
		button.pressed.connect(_on_perk_selected.bind(perk, button))
		perks_grid.add_child(button)
	
	update_perk_buttons()
	print("PerksScreen ready, grid children: ", perks_grid.get_child_count())

func show_perks(planet_data):
	visible = true
	chosen_perks.clear()
	selected_planet = planet_data
	get_tree().paused = false
	update_perk_buttons()
	print("Perks screen shown for planet: ", planet_data["name"], " Planet data: ", planet_data)

func _on_perk_hover(perk):
	perk_name_label.text = perk.capitalize()
	perk_desc_label.text = Perks.get_perk_description(perk)
	hover_panel.visible = true

func _on_perk_hover_exit():
	hover_panel.visible = false
	perk_name_label.text = ""
	perk_desc_label.text = ""

func _on_perk_selected(perk, button):
	if perk in chosen_perks:
		chosen_perks.erase(perk)
		print("Deselected perk: ", perk)
	else:
		if chosen_perks.size() < 3:
			chosen_perks.append(perk)
			print("Selected perk: ", perk)
		else:
			print("Max perks (3) already selected!")
	update_perk_buttons()

func update_perk_buttons():
	for button in perks_grid.get_children():
		if button is Button:
			var perk = button.text.to_lower()
			if perk in chosen_perks:
				button.modulate = Color(0, 1, 0)  # Green for selected
			else:
				button.modulate = Color(1, 1, 1)  # White for unselected
	print("Updated buttons, chosen perks: ", chosen_perks)

func _on_go_pressed():
	if selected_planet:
		Perks.set_active_perks(chosen_perks)
		print("Emitting perks_selected with perks: ", chosen_perks, " and planet: ", selected_planet["name"])
		emit_signal("perks_selected", chosen_perks, selected_planet)
		visible = false
		get_tree().paused = false
		selected_planet = null
	else:
		print("Error: No planet set!")
