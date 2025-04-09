extends Node3D

@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D

func _ready():
	# Start particles on spawn
	gpu_particles_3d.emitting = true
	# Connect the finished signal to queue_free
	gpu_particles_3d.connect("finished", _on_particles_finished)

func _on_particles_finished():
	queue_free()
