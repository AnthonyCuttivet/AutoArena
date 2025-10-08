class_name ProjectileBullet extends Projectile

@export var fx_hit:PackedScene;

@onready var trail: Line2D = $Trail

var rarity:int = 0;

func _process(delta: float) -> void:
	trail.points[1].x -= speed * delta * 0.75;

func set_trail_color(color: Color):
	var alphas:Array[float] = [trail.gradient.colors[0].a, trail.gradient.colors[1].a];
	trail.gradient.colors[0] = color;
	trail.gradient.colors[0].a = alphas[0];
	trail.gradient.colors[1] = color;
	trail.gradient.colors[1].a = alphas[1];

func on_hit_effect(other:BattleBall):

	for i in (rarity * 2) + 1:
		var fx:GPUParticles2D = ball_owner.main.spawn_fx(fx_hit, other.global_position, global_rotation);
		fx.modulate = trail.gradient.colors[0];
		fx.modulate.a = 1.0;
		fx.scale *= 2.0;
		fx.position += Vector2(randf_range(-20.0,20.0), randf_range(-20.0,20.0));
