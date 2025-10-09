class_name ProjectileScissors extends Projectile

@export var move_duration:float = 1.0;
@export var fixed_lifetime:float = 1.0;
@export var acceleration_curve:Curve;

var move_elapsed:float = 0.0;
var fixed_lifetime_elapsed:float = 0.0;
var fixed_dir:Vector2 = Vector2.ZERO;
var position_fixed:bool = false;

func init(o:BattleBall, s:float, _p:int = 0, _b:int = 0):
	super.init(o, s);

	fixed_dir = transform.x;

	if(acceleration_curve != null):
		velocity = fixed_dir * acceleration_curve.sample(0.0) * speed;
	else:
		velocity = fixed_dir * speed;

	var angle_to_center:float = rad_to_deg(fixed_dir.angle_to_point(ball_owner.main.arena_center.global_position));
	angle_to_center += rotation_speed;
	rotation_speed = angle_to_center / move_duration;

func _physics_process(delta: float) -> void:
	weapon_owner = ball_owner.weapon;

	move_elapsed += delta;

	if(!position_fixed):
		var ratio:float = move_elapsed / move_duration;
		velocity = fixed_dir * acceleration_curve.sample(ratio) * speed;
		global_position += velocity * delta;

	if(move_elapsed < move_duration):
		global_rotation_degrees += rotation_speed * delta;
	else:
		position_fixed = true;
		fixed_lifetime_elapsed += delta;
		var ratio:float = fixed_lifetime_elapsed / fixed_lifetime;
		if(ratio >= 0.9):
			ratio = remap(ratio,0.9,1.0,0.0,1.0);
			sprite_2d.material.set_shader_parameter("sensitivity", ratio);
		if(fixed_lifetime_elapsed >= fixed_lifetime):
			destroy();

func _on_projectile_hitbox_area_entered(other: Area2D) -> void:
	if(other is not Hurtbox): return;
	if(other.ball_owner != ball_owner): return;
	if(move_elapsed < move_duration): return;
	weapon_owner.start_dash(global_transform.x);
	destroy();

func _on_projectile_hitbox_body_entered(other: Node2D) -> void:
	if(absolute) : return;

	if(other.is_in_group("WALL")):
		position_fixed = true;

	if(other.is_in_group("DEADZONE")):
		destroy();
		return;
