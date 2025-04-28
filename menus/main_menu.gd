extends Control

@onready var star_map_bn: Button = $Menu_Container/CenterContainer2/ButtonContainer/StarMapBn
@onready var store_bn: Button = $Menu_Container/CenterContainer2/ButtonContainer/StoreBn
@onready var perf_review_bn: Button = $Menu_Container/CenterContainer2/ButtonContainer/PerfReviewBn
@onready var exit_bn: Button = $Menu_Container/CenterContainer2/ButtonContainer/ExitBn


func _ready():
	# Connect button signals
	star_map_bn.pressed.connect(_on_star_map_pressed)
	store_bn.pressed.connect(_on_store_pressed)
	perf_review_bn.pressed.connect(_on_stats_pressed)
	exit_bn.pressed.connect(_on_quit_pressed)

func _on_star_map_pressed():
	# Transition to Star Map scene
	get_tree().change_scene_to_file("res://starmenu/star_menu.tscn")
	print("Opening Star Map")

func _on_store_pressed():
	# Open Corporate Loyalty Store (assumes Store.tscn exists)
	get_tree().change_scene_to_file("res://menus/store_menu.tscn")
	print("Opening Corporate Store")

func _on_stats_pressed():
	get_tree().change_scene_to_file("res://menus/stats_menu.tscn")

func _on_quit_pressed():
	get_tree().quit()
	print("Quitting Game")
