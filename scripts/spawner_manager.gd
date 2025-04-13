extends Node

signal wave_started(wave)

var current_wave: int = 0
var is_night: bool = false

func _ready():
	print("SpawnerManager ready, awaiting night signal")

func start_night(wave: int):
	if not is_night:
		is_night = true
		current_wave = wave
		emit_signal("wave_started", wave)
		var active_spawners = 0
		for spawner in get_children():
			if spawner.has_method("activate_for_wave"):
				spawner.activate_for_wave(wave)
				if spawner.get("is_active") == true:
					active_spawners += 1
		print("Night started, wave ", wave, ", active spawners: ", active_spawners)
		if active_spawners == 0:
			print("Warning: No spawners activated for wave ", wave)

func end_night():
	is_night = false
	for spawner in get_children():
		if spawner.has_method("activate_for_wave"):
			spawner.activate_for_wave(0)  # Deactivate
	print("Night ended")

func has_active_spawners() -> bool:
	for spawner in get_children():
		if spawner.get("is_active") == true:
			return true
	return false
