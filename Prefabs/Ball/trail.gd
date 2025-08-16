class_name Trail2D extends Line2D

@export var length: int = 50;

var point: Vector2 = Vector2.ZERO;

func _process(delta: float) -> void:
	global_rotation = 0;
	global_position = Vector2.ZERO;

	add_point(get_parent().global_position);
	while (get_point_count() > length):
		remove_point(0);

func set_color(color: Color):
	var alphas:Array[float] = [gradient.colors[0].a, gradient.colors[1].a];
	gradient.colors[0] = color;
	gradient.colors[0].a = alphas[0];
	gradient.colors[1] = color;
	gradient.colors[1].a = alphas[1];
