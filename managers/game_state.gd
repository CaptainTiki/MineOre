extends Node

var completed_planets = []
var points = 0

func complete_planet(planet_name):
	if not completed_planets.has(planet_name):
		completed_planets.append(planet_name)
		points += 1

func is_planet_completed(planet_name):
	return completed_planets.has(planet_name)

func get_points():
	return points
