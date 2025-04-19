extends Panel
class_name PerksScreen

signal perks_selected(perks, planet_data)
signal perks_canceled

@onready var perks_grid = $PerksGrid
@onready var hover_panel = $HoverPanel
@onready var perk_name_label = $HoverPanel/VBoxContainer/PerkNameLabel
@onready var perk_desc_label = $HoverPanel/VBoxContainer/PerkDescLabel
@onready var paper_doll_panel = $PaperDollPanel
@onready var doll_label = $PaperDollPanel/DollLabel
@onready var go_button = $GoButton

var perk_icon_scene = preload("res://scenes/perks_icon.tscn")
var available_perks: Array[Perk] = []  # Now an array of Perk resources
var chosen_perks: Array[String] = []   # Stores perk IDs
var selected_planet = null
var current_perk_index: int = 0        # Start with the first perk highlighted
var mouse_hovered_icon = null

var can_navigate: bool = true
var nav_cooldown: float = 0.1          # 1/10th of a second cooldown

func _ready():
	visible = false
	go_button.pressed.connect(_on_go_pressed)
	doll_label.text = "Paper Doll\n(Coming Soon)"
	hover_panel.visible = false
	go_button.focus_mode = Control.FOCUS_ALL
	
	# Load all perks from PerksManager
	available_perks = PerksManager.get_all_perks()
	for perk in available_perks:
		var icon = perk_icon_scene.instantiate()
		icon.set_perk(perk)  # Pass the Perk resource
		icon.icon_pressed.connect(_on_perk_selected)
		icon.icon_hovered.connect(_on_perk_hover)
		icon.icon_unhovered.connect(_on_perk_hover_exit)
		perks_grid.add_child(icon)
	
	update_perk_buttons()

func _input(event):
	if visible and can_navigate:
		if Input.is_action_just_pressed("navigate_right"):
			navigate_right()
			start_nav_cooldown()
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("navigate_left"):
			navigate_left()
			start_nav_cooldown()
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("navigate_up"):
			navigate_up()
			start_nav_cooldown()
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("navigate_down"):
			navigate_down()
			start_nav_cooldown()
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("select") and current_perk_index >= 0:
			_on_perk_selected(available_perks[current_perk_index].id)
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("cancel"):
			visible = false
			get_tree().paused = false
			selected_planet = null
			emit_signal("perks_canceled")
			get_viewport().set_input_as_handled()

func start_nav_cooldown():
	can_navigate = false
	await get_tree().create_timer(nav_cooldown).timeout
	can_navigate = true

func navigate_right():
	var old_index = current_perk_index
	current_perk_index = (current_perk_index + 1) % perks_grid.get_child_count()
	print("Navigating right from index ", old_index, " to ", current_perk_index)
	update_controller_highlight()

func navigate_left():
	var old_index = current_perk_index
	current_perk_index = (current_perk_index - 1 + perks_grid.get_child_count()) % perks_grid.get_child_count()
	print("Navigating left from index ", old_index, " to ", current_perk_index)
	update_controller_highlight()

func navigate_up():
	var columns = perks_grid.columns
	var child_count = perks_grid.get_child_count()
	var old_index = current_perk_index
	current_perk_index = (current_perk_index - columns + child_count) % child_count
	print("Navigating up from index ", old_index, " to ", current_perk_index)
	update_controller_highlight()

func navigate_down():
	var columns = perks_grid.columns
	var child_count = perks_grid.get_child_count()
	var old_index = current_perk_index
	current_perk_index = (current_perk_index + columns) % child_count
	print("Navigating down from index ", old_index, " to ", current_perk_index)
	update_controller_highlight()

func show_perks(planet_data):
	if visible and selected_planet and selected_planet["name"] == planet_data["name"]:
		return
	visible = true
	chosen_perks = []
	selected_planet = planet_data
	get_tree().paused = false
	current_perk_index = 0
	update_perk_buttons()
	update_controller_highlight()
	go_button.grab_focus()

func _on_perk_hover(perk_id: String):
	var perk = PerksManager.get_perk_by_id(perk_id)
	if perk:
		for icon in perks_grid.get_children():
			if icon.perk_name == perk_id:  # perk_name is the ID
				if mouse_hovered_icon and mouse_hovered_icon != icon:
					mouse_hovered_icon.set_highlight(false)
				mouse_hovered_icon = icon
				icon.set_highlight(true)
				break
		perk_name_label.text = perk.name
		perk_desc_label.text = perk.description
		hover_panel.visible = true
	else:
		hover_panel.visible = false

func _on_perk_hover_exit():
	if mouse_hovered_icon:
		mouse_hovered_icon.set_highlight(false)
		mouse_hovered_icon = null
	update_controller_highlight()

func _on_perk_selected(perk_id: String):
	var perk = PerksManager.get_perk_by_id(perk_id)
	if perk and perk.unlocked:
		if perk_id in chosen_perks:
			chosen_perks.erase(perk_id)
		else:
			if chosen_perks.size() < 3:
				chosen_perks.append(perk_id)
		update_perk_buttons()
		if current_perk_index >= 0:
			update_controller_highlight()
	else:
		print("Cannot select locked perk: ", perk_id)

func update_perk_buttons():
	for icon in perks_grid.get_children():
		if icon is Control and icon.has_method("set_selected"):
			var perk_id = icon.perk_name  # perk_name is the ID
			var is_selected = perk_id in chosen_perks
			icon.set_selected(is_selected)

func update_controller_highlight():
	if mouse_hovered_icon:
		return
	for icon in perks_grid.get_children():
		icon.set_highlight(false)
	if current_perk_index >= 0 and current_perk_index < perks_grid.get_child_count():
		var icon = perks_grid.get_child(current_perk_index)
		if icon:
			icon.set_highlight(true)
			var perk = available_perks[current_perk_index]
			print("Highlighting controller perk at index ", current_perk_index, ": ", perk.id)
			perk_name_label.text = perk.name
			perk_desc_label.text = perk.description
			hover_panel.visible = true
	else:
		hover_panel.visible = false
		perk_name_label.text = ""
		perk_desc_label.text = ""

func _on_go_pressed():
	if selected_planet:
		PerksManager.set_active_perks(chosen_perks)  # Updated to PerksManager
		print("Emitting perks_selected with perks: ", chosen_perks, " and planet: ", selected_planet["name"])
		emit_signal("perks_selected", chosen_perks, selected_planet)
		visible = false
		get_tree().paused = false
		selected_planet = null
