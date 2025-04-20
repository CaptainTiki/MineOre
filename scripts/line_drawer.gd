extends Control

var start_pos: Vector2
var end_pos: Vector2
var progress: float = 0.0

func _draw():
	if progress > 0:
		draw_line(start_pos, start_pos + (end_pos - start_pos) * progress, Color(0, 0.5, 1), 2.0)  # Blue holographic line

func _process(_delta):
	queue_redraw()  # Ensure the line updates as progress changesextends Node
