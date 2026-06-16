extends Node2D

var parent_module

func _process(_delta):
	queue_redraw()

func _draw():
	if not parent_module:
		return
	parent_module._draw_lines(self)
