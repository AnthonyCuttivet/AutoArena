class_name Trail2D extends Line2D

@export var length: int = 50;
@export var pos_reference: Node2D;

func _process(delta: float) -> void:
	add_point(pos_reference.global_position);
	while (get_point_count() > length):
		remove_point(0);

func set_color(color: Color):
	var alphas:Array[float] = [gradient.colors[0].a, gradient.colors[1].a];
	gradient.colors[0] = color;
	gradient.colors[0].a = alphas[0];
	gradient.colors[1] = color;
	gradient.colors[1].a = alphas[1];
