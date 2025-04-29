# res://scenes/store_menu.gd
extends Control

@export var unaffordable_style: StyleBox

@onready var clp_label: Label = $MainContainer/CLPLabel
@onready var buildings_tab: Button = $MainContainer/TabContainer/BuildingsTab
@onready var perks_tab: Button = $MainContainer/TabContainer/PerksTab
@onready var curses_tab: Button = $MainContainer/TabContainer/CursesTab
@onready var player_unlocks_tab: Button = $MainContainer/TabContainer/PlayerUnlocksTab
@onready var item_container: VBoxContainer = $MainContainer/ContentContainer/ItemScroll/ItemContainer
@onready var description_label: Label = $MainContainer/ContentContainer/DescriptionPanel/DescriptionLabel
@onready var back_button: Button = $MainContainer/BackButton
@onready var purchase_popup: Panel = $PurchasePopup
@onready var buy_button: Button = $PurchasePopup/VBoxContainer/HBoxContainer/BuyButton
@onready var cancel_button: Button = $PurchasePopup/VBoxContainer/HBoxContainer/CancelButton
@onready var confirm_label: Label = $PurchasePopup/VBoxContainer/ConfirmLabel

var current_tab: String = "buildings"
var selected_item: Dictionary = {} # {type: String, id: String}
var item_buttons: Array[Button] = []

func _ready():
	purchase_popup.visible = false
	selected_item = {}
	
	buildings_tab.pressed.connect(_on_tab_pressed.bind("buildings"))
	perks_tab.pressed.connect(_on_tab_pressed.bind("perks"))
	curses_tab.pressed.connect(_on_tab_pressed.bind("curses"))
	player_unlocks_tab.pressed.connect(_on_tab_pressed.bind("player_unlocks"))
	back_button.pressed.connect(on_cancel_pressed)
	buy_button.pressed.connect(_on_buy_confirmed)
	cancel_button.pressed.connect(_on_buy_cancelled)
	
	update_clp_display()
	_on_tab_pressed("buildings")
	
	buildings_tab.grab_focus()

func _input(event):
	if event.is_action_pressed("cancel"):
		if purchase_popup.visible:
			_on_buy_cancelled()
		else:
			on_cancel_pressed()
	if event.is_action_pressed("leveldebug"):
		GameState.clp += 150
		update_clp_display()
		_on_tab_pressed(current_tab)

func update_clp_display():
	clp_label.text = "CLP: %d" % GameState.clp

func _on_tab_pressed(tab: String):
	current_tab = tab
	populate_store()
	
	buildings_tab.disabled = tab == "buildings"
	perks_tab.disabled = tab == "perks"
	curses_tab.disabled = tab == "curses"
	player_unlocks_tab.disabled = tab == "player_unlocks"

func populate_store():
	for child in item_container.get_children():
		child.queue_free()
	item_buttons.clear()
	
	var available_items = StoreManager.get_available_items(GameState.player_level)
	var items = available_items[current_tab]
	
	for item in items:
		add_store_item(current_tab, item.id, item.clp_cost)
	
	for i in item_buttons.size():
		var button = item_buttons[i]
		if i > 0:
			button.focus_neighbor_top = item_buttons[i-1].get_path()
		if i < item_buttons.size() - 1:
			button.focus_neighbor_bottom = item_buttons[i+1].get_path()
		button.focus_neighbor_left = buildings_tab.get_path()
		button.focus_neighbor_right = player_unlocks_tab.get_path()

func add_store_item(item_type: String, item_id: String, clp_cost: int):
	var normalized_type = normalize_item_type(item_type)
	var button = Button.new()
	var is_purchased = StoreManager.is_purchased(normalized_type, item_id)
	var can_afford = GameState.clp >= clp_cost
	
	button.text = item_id.capitalize() + (" (Purchased)" if is_purchased else "")
	button.theme = load("res://menus/ButtonTheme.tres")
	
	if is_purchased:
		button.disabled = true
	elif not can_afford:
		button.disabled = true
		button.add_theme_stylebox_override("disabled", unaffordable_style)
	else:
		button.disabled = false
	
	button.mouse_entered.connect(_on_item_hovered.bind(item_type, item_id))
	button.focus_entered.connect(_on_item_hovered.bind(item_type, item_id))
	button.pressed.connect(_on_item_selected.bind(normalized_type, item_id))
	
	item_container.add_child(button)
	item_buttons.append(button)

func normalize_item_type(item_type: String) -> String:
	match item_type:
		"buildings":
			return "building"
		"perks":
			return "perk"
		"curses":
			return "curse"
		"player_unlocks":
			return "player"
		_:
			return item_type

func _on_item_hovered(item_type: String, item_id: String):
	var normalized_type = normalize_item_type(item_type)
	var description = get_item_description(normalized_type, item_id)
	var clp_cost = get_item_cost(normalized_type, item_id)
	var status = ""
	if StoreManager.is_purchased(normalized_type, item_id):
		status = "\nAlready Purchased"
	elif GameState.clp < clp_cost:
		status = "\nNot Enough CLP"
	description_label.text = "%s\nCost: %d CLP%s" % [description, clp_cost, status]

func _on_item_selected(item_type: String, item_id: String):
	var clp_cost = get_item_cost(item_type, item_id)
	if StoreManager.is_purchased(item_type, item_id):
		description_label.text = "Cannot purchase: Already purchased"
	elif GameState.clp < clp_cost:
		description_label.text = "Cannot purchase: Not enough CLP (%d required)" % clp_cost
	else:
		selected_item = {"type": item_type, "id": item_id}
		confirm_label.text = "Purchase %s for %d CLP?" % [item_id.capitalize(), clp_cost]
		purchase_popup.visible = true
		buy_button.grab_focus()

func _on_buy_confirmed():
	if selected_item.is_empty():
		return
	var item_type = selected_item.type
	var item_id = selected_item.id
	if StoreManager.purchase_item(item_type, item_id):
		print("Purchased %s: %s" % [item_type, item_id])
		update_clp_display()
		_on_buy_cancelled()
		_on_tab_pressed(current_tab)
	else:
		print("Failed to purchase %s: %s" % [item_type, item_id])
		_on_buy_cancelled()
		description_label.text = "Purchase failed: Not enough CLP"

func _on_buy_cancelled():
	purchase_popup.visible = false
	selected_item = {}
	description_label.text = "Hover or select an item to view its description."
	if !item_buttons.is_empty():
		item_buttons[0].grab_focus()
	else:
		buildings_tab.grab_focus()

func get_item_description(item_type: String, item_id: String) -> String:
	match item_type:
		"building":
			match item_id:
				"refinery":
					return "Converts 2 raw ore into 1 refined ore every 5 seconds."
				"ordnance_facility":
					return "Unlocks Minigun Turrets for advanced defense."
				"minigun":
					return "High fire-rate turret for rapid enemy suppression."
				_:
					var building = BuildingsManager.get_building_resource(item_id)
					return building.research_description if building and building.research_description else "Unlocks " + item_id.capitalize()
		"perk":
			var perk = PerksManager.get_perk_by_id(item_id)
			return perk.description if perk else "Boosts " + item_id.capitalize()
		"curse":
			return "Applies " + item_id.capitalize() + " effect"
		"player":
			return "Grants " + item_id.capitalize() + " ability"
	return "No description available"

func get_item_cost(item_type: String, item_id: String) -> int:
	var available_items = StoreManager.get_available_items(GameState.player_level)
	var tab_type = denormalize_item_type(item_type)
	for item in available_items[tab_type]:
		if item.id == item_id:
			return item.clp_cost
	return 0

func denormalize_item_type(normalized_type: String) -> String:
	match normalized_type:
		"building":
			return "buildings"
		"perk":
			return "perks"
		"curse":
			return "curses"
		"player":
			return "player_unlocks"
		_:
			return normalized_type

func on_cancel_pressed():
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
