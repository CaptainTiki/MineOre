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

var perk_icon_scene = preload("res://scenes/perks_icon.tscn")
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
		var icon = perk_icon_scene.instantiate()
		icon.set_perk(perk)
		icon.icon_pressed.connect(_on_perk_selected)  # Direct connection
		icon.icon_hovered.connect(_on_perk_hover)
		icon.icon_unhovered.connect(_on_perk_hover_exit)
		perks_grid.add_child(icon)
	
	update_perk_buttons()

func show_perks(planet_data):
	if visible and selected_planet and selected_planet["name"] == planet_data["name"]:
		return
	visible = true
	chosen_perks = []
	selected_planet = planet_data
	get_tree().paused = false
	update_perk_buttons()

func _on_perk_hover(perk):
	perk_name_label.text = perk.capitalize()
	perk_desc_label.text = Perks.get_perk_description(perk)
	hover_panel.visible = true

func _on_perk_hover_exit():
	hover_panel.visible = false
	perk_name_label.text = ""
	perk_desc_label.text = ""

func _on_perk_selected(perk):
	if perk in chosen_perks:
		chosen_perks.erase(perk)
	else:
		if chosen_perks.size() < 3:
			chosen_perks.append(perk)
	update_perk_buttons()

func update_perk_buttons():
	for icon in perks_grid.get_children():
		if icon is Control and icon.has_method("set_selected"):
			var perk = icon.perk_name
			var is_selected = perk in chosen_perks
			icon.set_selected(is_selected)

func _on_go_pressed():
	if selected_planet:
		Perks.set_active_perks(chosen_perks)
		print("Emitting perks_selected with perks: ", chosen_perks, " and planet: ", selected_planet["name"])
		emit_signal("perks_selected", chosen_perks, selected_planet)
		visible = false
		get_tree().paused = false
		selected_planet = null
