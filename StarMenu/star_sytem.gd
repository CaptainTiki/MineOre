extends Area3D

signal clicked(resource: StarSystemResource)

@export var resource: StarSystemResource

@onready var star: MeshInstance3D = $Star
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	self.visible = false
	if resource:
		# Replace the default Star mesh with the one from the resource
		if resource.star_scene:
			# Remove the default Star node
			star.queue_free()
			
			# Instantiate the star_scene from the resource
			var newstar = resource.star_scene.instantiate()
			newstar.name = resource.system_name + "_Star"
			add_child(newstar)

func play_anim(animation_name : String) -> void:
	animation_player.play(animation_name)

func _input_event(_camera, event: InputEvent, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if resource:
			emit_signal("clicked", resource)
