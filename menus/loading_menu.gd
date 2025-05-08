extends CanvasLayer

var loader = null

func _ready():
	print("loading scene loaded")
	var path = LevelManager.level_path
	if path == "":
		print("Error: No level path set")
		return
	ResourceLoader.load_threaded_request(path)
	var label_tween = create_tween().set_loops()
	label_tween.tween_property($ColorRect/Label, "modulate", Color(1, 1, 1, 0.5), 0.5)
	label_tween.tween_property($ColorRect/Label, "modulate", Color(1, 1, 1, 1), 0.5)

func _process(_delta):
	var path = LevelManager.level_path
	var status = ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed_scene = ResourceLoader.load_threaded_get(path)
		get_tree().change_scene_to_packed(packed_scene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		print("Failed to load scene: ", path)
		# Handle error, e.g., go back to star menu
		get_tree().change_scene_to_file("res://menus/main_menu.tscn")
