extends Node

var planets: Dictionary = {}  # id -> Planet

func _ready():
	load_planets()

func load_planets():
	var dir = DirAccess.open("res://planets/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var planet = load("res://planets/" + file_name) as Resource
				if planet and planet.id != "":
					if planet.id in planets:
						push_error("Duplicate planet id: " + planet.id)
					else:
						planets[planet.id] = planet
				else:
					push_warning("Invalid planet file: " + file_name)
			file_name = dir.get_next()
	else:
		push_error("Failed to open res://planets/")

func is_planet_unlocked(planet_id: String) -> bool:
	if planet_id in planets:
		return planets[planet_id].unlocked
	return false

func unlock_planet(planet_id: String):
	if planet_id in planets:
		planets[planet_id].unlocked = true
		print("Planet unlocked: ", planet_id)
	else:
		push_error("Planet not found: " + planet_id)

func has_planet(planet_id: String) -> bool:
	return planet_id in planets
