extends Node3D

@export var start_node: NodePath
@export var end_node: NodePath

@onready var line_mesh = $LineMesh
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	# Replace ImmediateMesh with CylinderMesh
	line_mesh.mesh = CylinderMesh.new()
	var start = get_node_or_null(start_node)
	var end = get_node_or_null(end_node)
	if start and end:
		setup_line(start, end)

func setup_line(start: Node3D, end: Node3D):
	# Get the global positions of the start and end nodes
	var start_pos = start.global_transform.origin
	var end_pos = end.global_transform.origin
	
	# Calculate the direction and length between the nodes
	var direction = end_pos - start_pos
	var length = direction.length()
	var midpoint = (start_pos + end_pos) / 2

	# Position the cylinder at the midpoint
	line_mesh.global_transform.origin = midpoint

	# Define an up vector for orientation, avoiding gimbal lock
	var up = Vector3.UP
	if direction.normalized().is_equal_approx(up) or direction.normalized().is_equal_approx(-up):
		up = Vector3.FORWARD

	# Create a basis to align the cylinder's Y-axis with the direction
	var basis = Basis()
	basis.y = direction.normalized()
	basis.x = up.cross(basis.y).normalized()
	basis.z = basis.x.cross(basis.y).normalized()

	# Apply the rotation to the cylinder
	line_mesh.global_transform.basis = basis

	# Scale the cylinder to match the distance (default height is 2 units)
	line_mesh.scale = Vector3(1, length / 2.25, 1)

	# Set the cylinder thickness
	var cylinder_mesh = line_mesh.mesh as CylinderMesh
	cylinder_mesh.top_radius = 1
	cylinder_mesh.bottom_radius = 1

	# Optional: Set a material for visibility
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0) # Red color
	line_mesh.material_override = material
	line_mesh.visible = false

func play_anim(animation_name: String):
	if animation_player.has_animation(animation_name):
		animation_player.stop(false)
		animation_player.play(animation_name)
