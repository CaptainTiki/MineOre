extends Node3D
class_name PerksView

signal load_level_selected

@onready var perks_grid = $MarginContainer/VBoxContainer/MidContainer/GridPanel/PerksGrid
@onready var hover_panel = $MarginContainer/VBoxContainer/MidContainer/HoverPanel
@onready var perk_name_label = $MarginContainer/VBoxContainer/MidContainer/HoverPanel/VBoxContainer/PerkNameLabel
@onready var perk_desc_label = $MarginContainer/VBoxContainer/MidContainer/HoverPanel/VBoxContainer/PerkDescLabel
@onready var paper_doll_panel = $MarginContainer/VBoxContainer/MidContainer/PaperDollPanel
@onready var doll_label = $MarginContainer/VBoxContainer/MidContainer/PaperDollPanel/DollLabel
@onready var go_button = $MarginContainer/VBoxContainer/Button_Wrapper/GoButton
@onready var go_button_progress_bar: ProgressBar = $MarginContainer/VBoxContainer/Button_Wrapper/GoButton/GoButtonProgressBar

var perk_icon_scene = preload("res://StarMenu/perks_icon.tscn")
var available_perks : Array[Perk] = []  # Now an array of Perk resources
var chosen_perks : Array[String] = []   # Stores perk IDs
var current_perk_index: int = 0        # Start with the first perk highlighted
var mouse_hovered_icon = null

var can_navigate : bool = true
var nav_cooldown : float = 0.1
var is_active: bool = false #indicator that we can process input 
var current_planet : Planet

var select_hold_time: float = 0.0
var is_holding_select: bool = false
const HOLD_DURATION: float = 0.75  # 3/4 second to trigger DROP!
var original_position: Vector2
var transition_triggered: bool = false

func _ready():
	visible = false
	$MarginContainer.visible = false
	go_button.pressed.connect(_on_go_pressed)
	doll_label.text = "Paper Doll\n(Coming Soon)"
	hover_panel.visible = false
	current_perk_index = 0
	original_position = go_button.position
	
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

func _process(delta):
	if is_active and visible and is_holding_select and not transition_triggered:
		select_hold_time += delta
		var progress = (select_hold_time / HOLD_DURATION) * 100
		go_button_progress_bar.value = progress
		
		# Vibrate the button
		var amplitude = (select_hold_time / HOLD_DURATION) * 8  # Max 8 pixels
		var angle = randf() * 2 * PI
		var radius = randf() * amplitude
		var offset_x = cos(angle) * radius
		var offset_y = sin(angle) * radius
		go_button.position = original_position + Vector2(offset_x, offset_y)
		if select_hold_time >= HOLD_DURATION:
			transition_triggered = true
			_on_go_pressed()
	else:
		go_button.position = original_position
		go_button_progress_bar.value = 0


func enable_view() -> void:
	visible = true
	$MarginContainer.visible = true
	is_active = true
	set_process(true)

	update_perk_buttons()
	update_controller_highlight()

func disable_view() -> void:
	visible = false
	$MarginContainer.visible = false
	is_active = false
	set_process(false)

func _input(event):
	if is_active and visible:
		if event.is_action_pressed("select"):
			is_holding_select = true
			select_hold_time = 0.0  # Reset hold time
			transition_triggered = false
			get_viewport().set_input_as_handled()
		elif event.is_action_released("select"):
			if is_holding_select and not transition_triggered:
				if select_hold_time < HOLD_DURATION:
					# Quick tap: select perk
					if current_perk_index >= 0:
						_on_perk_selected(available_perks[current_perk_index].id)
			is_holding_select = false
			get_viewport().set_input_as_handled()
		elif not is_holding_select and can_navigate:
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

func start_nav_cooldown():
	can_navigate = false
	await get_tree().create_timer(nav_cooldown).timeout
	can_navigate = true

func navigate_right():
	current_perk_index = (current_perk_index + 1) % perks_grid.get_child_count()
	update_controller_highlight()

func navigate_left():
	current_perk_index = (current_perk_index - 1 + perks_grid.get_child_count()) % perks_grid.get_child_count()
	update_controller_highlight()

func navigate_up():
	var columns = perks_grid.columns
	var child_count = perks_grid.get_child_count()
	current_perk_index = (current_perk_index - columns + child_count) % child_count
	update_controller_highlight()

func navigate_down():
	var columns = perks_grid.columns
	var child_count = perks_grid.get_child_count()
	current_perk_index = (current_perk_index + columns) % child_count
	update_controller_highlight()

func set_planet(planet : Node3D) -> void:
	current_planet = planet

func _on_perk_hover(perk_id: String):
	var perk = PerksManager.get_perk_by_id(perk_id)
	if perk:
		for icon in perks_grid.get_children():
			if icon is PerksIcon:
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

func update_perk_buttons():
	for icon in perks_grid.get_children():
		if icon is PerksIcon:
			var perk_id = icon.perk_name  # perk_name is the ID
			var is_selected = perk_id in chosen_perks
			icon.set_selected(is_selected)

func update_controller_highlight():
	if mouse_hovered_icon:
		return
	for icon in perks_grid.get_children():
		if icon is PerksIcon:
			icon.set_highlight(false)
	if current_perk_index >= 0 and current_perk_index < perks_grid.get_child_count():
		var icon = perks_grid.get_child(current_perk_index)
		if icon is PerksIcon:
			icon.set_highlight(true)
			var perk = available_perks[current_perk_index]
			perk_name_label.text = perk.name
			perk_desc_label.text = perk.description
			hover_panel.visible = true
	else:
		hover_panel.visible = false
		perk_name_label.text = ""
		perk_desc_label.text = ""

func _on_go_pressed():
	print("dropping to planet!")
	if current_planet:
		print("current planet: " + current_planet.planet_name)
		PerksManager.set_active_perks(chosen_perks)  # Updated to PerksManager
		emit_signal("load_level_selected")
