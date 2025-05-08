# res://buildings/ore_silo.gd
extends Building

signal silo_destroyed

@onready var hq = get_tree().get_root().get_node_or_null("Level/Buildings/HeadQuarters")

func _ready():
	super._ready()
	add_to_group("silos")
	if hq and hq.has_method("add_silo"):
		hq.add_silo()
		print("Silo added at %s" % global_position)

func take_damage(amount):
	if health <= 0:
		if hq and hq.has_method("remove_silo"):
			hq.remove_silo()
	super.take_damage(amount)

func _on_destroyed():
	if hq and hq.has_method("remove_silo"):
		hq.remove_silo()
		print("Silo removed at %s" % global_position)
	super._on_destroyed()
