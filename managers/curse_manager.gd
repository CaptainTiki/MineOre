extends Node

var curses: Dictionary = {}  # id -> Curse

func _ready():
	load_curses()

func load_curses():
	var dir = DirAccess.open("res://curses/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var curse = load("res://curses/" + file_name) as Resource
				if curse and curse.id != "":
					if curse.id in curses:
						push_error("Duplicate curse id: " + curse.id)
					else:
						curses[curse.id] = curse
				else:
					push_warning("Invalid curse file: " + file_name)
			file_name = dir.get_next()
	else:
		push_error("Failed to open res://curses/")

func is_curse_unlocked(curse_id: String) -> bool:
	if curse_id in curses:
		return curses[curse_id].unlocked
	return false

func unlock_curse(curse_id: String):
	if curse_id in curses:
		curses[curse_id].unlocked = true
		print("Curse unlocked: ", curse_id)
	else:
		push_error("Curse not found: " + curse_id)

func has_curse(curse_id: String) -> bool:
	return curse_id in curses
