extends Node3D

enum ViewState { STAR_MAP, SYSTEM, PLANET, PERKS }

var current_state = ViewState.STAR_MAP
var current_system: StarSystemResource = null
var current_planet: Node3D = null

@onready var star_map_view = $StarMapView
@onready var system_view = $SystemView
@onready var planet_view = $PlanetView
@onready var perks_view = $PerksView
@onready var camera = $Camera3D

func _ready():
	star_map_view.connect("system_selected", _on_system_selected)
	system_view.connect("planet_selected", _on_planet_selected)
	planet_view.connect("perks_selected", _on_perks_selected)
	planet_view.connect("level_selected", _on_level_selected)
	perks_view.connect("perks_confirmed", _on_perks_confirmed)
	
	# Pass StarSystems node to StarMapView
	star_map_view.set_systems($StarSystems)
	transition_to(ViewState.STAR_MAP)

func _on_system_selected(system: StarSystemResource):
	current_system = system
	transition_to(ViewState.SYSTEM)

func _on_planet_selected(planet: Node3D):
	current_planet = planet
	transition_to(ViewState.PLANET)

func _on_perks_selected():
	transition_to(ViewState.PERKS)

func _on_perks_confirmed():
	transition_to(ViewState.PLANET)

func _on_level_selected(level: PackedScene):
	get_tree().change_scene_to_packed(level)

func transition_to(new_state: ViewState):
	current_state = new_state
	match new_state:
		ViewState.STAR_MAP:
			star_map_view.show()
			system_view.hide()
			planet_view.hide()
			perks_view.hide()
			camera.position = Vector3(0, 0, 350)
			camera.look_at(Vector3(0, 0, 0), Vector3.UP)
		ViewState.SYSTEM:
			star_map_view.hide()
			system_view.show()
			system_view.set_system(current_system)
			planet_view.hide()
			perks_view.hide()
			camera.position = Vector3(0, 5, 10)
			camera.look_at(Vector3(0, 0, 0), Vector3.UP)
		ViewState.PLANET:
			star_map_view.hide()
			system_view.hide()
			planet_view.show()
			planet_view.set_planet(current_planet)
			perks_view.hide()
			camera.position = Vector3(0, 2, 5)
			camera.look_at(Vector3(0, 0, 0), Vector3.UP)
		ViewState.PERKS:
			star_map_view.hide()
			system_view.hide()
			planet_view.hide()
			perks_view.show()
			perks_view.set_planet(current_planet)
			camera.position = Vector3(0, 2, 5)
			camera.look_at(Vector3(0, 0, 0), Vector3.UP)
