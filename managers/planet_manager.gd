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
						print("Loaded planet: %s, Unlocked: %s, Points Required: %d" % [planet.id, planet.unlocked, planet.points_required])
				else:
					push_warning("Invalid planet file: " + file_name)
			file_name = dir.get_next()
	else:
		push_error("Failed to open res://planets/")

func is_planet_unlocked(planet_id: String) -> bool:
	if planet_id in planets:
		return planets[planet_id].unlocked
	return false

func unlock_planet(_planet_id: String):
	# Unlock planets based on GameState.planet_completion_points
	var points = GameState.planet_completion_points
	for planet_id in planets:
		var planet = planets[planet_id]
		if not planet.unlocked and points >= planet.points_required:
			planet.unlocked = true
			print("Planet unlocked: %s (Points: %d, Required: %d)" % [planet_id, points, planet.points_required])
		else:
			print("Planet %s not unlocked: Points: %d, Required: %d" % [planet_id, points, planet.points_required])

func has_planet(planet_id: String) -> bool:
	return planet_id in planets

func get_unlocked_planets() -> Array:
	var unlocked = []
	for planet_id in planets:
		if planets[planet_id].unlocked:
			unlocked.append(planets[planet_id])
	return unlocked
