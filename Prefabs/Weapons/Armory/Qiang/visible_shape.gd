class_name VisibleShape extends Node2D

@export var radius: float = 16.0
@export var height: float = 32.0
@export var color: Color = Color(1, 0, 0, 0.5)

func _draw():
	var top = Vector2(0, -height/2)
	var bottom = Vector2(0, height/2)
	draw_circle(top, radius, color)
	draw_circle(bottom, radius, color)
	draw_rect(Rect2(Vector2(-radius, -height/2), Vector2(radius*2, height)), color)
