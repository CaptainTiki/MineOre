extends Area3D
class_name Star_System

signal clicked(resource: StarSystemResource)

@export var system_resource: StarSystemResource
@export var star_mesh : Mesh

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var star: MeshInstance3D = $StarMesh


func _ready():
	star.mesh = star_mesh
	self.visible = true

func play_anim(animation_name : String) -> void:
	animation_player.play(animation_name)

func _input_event(_camera, event: InputEvent, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if system_resource:
			emit_signal("clicked", system_resource)
