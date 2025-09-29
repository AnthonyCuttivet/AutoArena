class_name ProjectileBullet extends Projectile

@onready var trail: Line2D = $Trail

func _process(delta: float) -> void:
	trail.points[1].x -= speed * delta * 0.5;

func set_trail_color(color: Color):
	var alphas:Array[float] = [trail.gradient.colors[0].a, trail.gradient.colors[1].a];
	trail.gradient.colors[0] = color;
	trail.gradient.colors[0].a = alphas[0];
	trail.gradient.colors[1] = color;
	trail.gradient.colors[1].a = alphas[1];
