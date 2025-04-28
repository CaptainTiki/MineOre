extends Control


func _ready() -> void:
	# Show Performance Review (could be a popup or new scene)
	var stats = StatsManager.get_stats()
	var stats_text = "Performance Review:\n"
	stats_text += "Missions Completed: %d\n" % stats.missions_completed
	stats_text += "Ore Mined: %d\n" % stats.ore_mined
	stats_text += "Enemies Killed: %d\n" % stats.enemies_killed
	stats_text += "Waves Survived: %d\n" % stats.waves_survived
	stats_text += "CLP Earned: %d\n" % stats.clp_earned
	# For now, show in a popup (replace with a proper UI later)
	var dialog = AcceptDialog.new()
	dialog.dialog_text = stats_text
	dialog.title = "Performance Review"
	add_child(dialog)
	dialog.popup_centered()
	print("Showing Performance Review")

func _input(event):
	if event.is_action_pressed("cancel"):
		print("cancel pressed")
		on_cancel_pressed()

func on_cancel_pressed():
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
