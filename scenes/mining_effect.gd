# res://scripts/mining_effect.gd
extends GPUParticles3D

func _ready():
	emitting = true
	finished.connect(queue_free)
