class_name Trail2D extends Line2D

@export var length: int = 50;
@export var pos_reference: Node2D;

var active:bool = true;
var base_length:int = 0;

func _init():
	base_length = length;

func _process(_delta: float) -> void:
	global_position = Vector2.ZERO
	global_rotation = 0.0
	global_scale = Vector2.ONE

	add_point(pos_reference.global_position)
	while (get_point_count() > length):
		remove_point(0)

func set_active(s:bool):
	active = s;
	length = base_length if s else 0;

func set_color(color: Color):
	var alphas:Array[float] = [gradient.colors[0].a, gradient.colors[1].a];
	gradient.colors[0] = color;
	gradient.colors[0].a = alphas[0];
	gradient.colors[1] = color;
	gradient.colors[1].a = alphas[1];
