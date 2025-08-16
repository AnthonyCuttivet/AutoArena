class_name BallGravity extends Node2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var fx_death_yes: GPUParticles2D = $FX/FXDeathYes
@onready var fx_death_no: GPUParticles2D = $FX/FXDeathNo
@onready var trail: Trail2D = $Trail

var arena: ArenaCircle = null;
var in_collision: bool = false;
var velocity: Vector2 = Vector2.ZERO;
var is_out: bool = false;
var team: int = -1;

func init(vel_x: Vector2, vel_y: float, color: Color):
	velocity.x = randf_range(vel_x.x, vel_x.y);
	velocity.y = vel_y;
	sprite_2d.modulate = color;
	trail.modulate = color;

func update(delta: float):
	if (arena.over):
		kill_ball();
		return ;

	velocity.y = clamp(velocity.y + arena.gravity, -arena.max_y_vel, arena.max_y_vel);
	self.position += velocity * delta;

	check_is_out();
	update_circle_collision();

func update_circle_collision():
	if (is_out): return ;
	if (is_in_hole()): return ;
	var dist_to_center: float = self.position.distance_to(arena.circle_center);
	if (dist_to_center < arena.circle_radius - arena.ball_radius): return ;

	var normal: Vector2 = (arena.circle_center - self.position);
	self.position = arena.circle_center + (arena.circle_radius - arena.ball_radius) * -normal.normalized();
	var tangeant: Vector2 = Vector2(-normal.y, normal.x);
	var projection: Vector2 = velocity.dot(tangeant) / tangeant.dot(tangeant) * tangeant;
	velocity = 2 * projection - velocity;

	if (arena.active_balls_count == 2):
		var d: Vector2 = (get_hole_pos() - self.position);
		velocity += (d * 0.9);

	arena.play_sfx();

func is_in_hole() -> bool:
	var dx: float = self.position.x - arena.circle_center.x;
	var dy: float = self.position.y - arena.circle_center.y;
	var ball_angle: float = atan2(dy, dx);
	var end_angle: float = fmod(deg_to_rad(arena.gap_angle_end - 90.0), (PI * 2.0));
	var start_angle: float = fmod(deg_to_rad(arena.gap_angle_start - 90.0), (PI * 2.0));
	if (start_angle > end_angle):
		end_angle += PI * 2.0;
	if ((start_angle <= ball_angle and ball_angle <= end_angle) or (start_angle <= ball_angle + PI * 2.0 and ball_angle + PI * 2.0 <= end_angle)):
		return true;

	return false;

func get_hole_pos() -> Vector2:
	return arena.circle_center + Vector2(cos(deg_to_rad(arena.gap_angle_start - 90.0)), sin(deg_to_rad(arena.gap_angle_start - 90.0))) * (arena.circle_radius - arena.ball_radius);

func check_is_out():
	if (is_out): return ;
	var dist_to_center: float = self.position.distance_to(arena.circle_center);
	is_out = dist_to_center > arena.circle_radius * 1.01 + arena.ball_radius;

	if (is_out):
		arena.on_ball_out(self);
		self.on_ball_out();

func on_ball_out():
	sprite_2d.visible = false;

	var fx = fx_death_yes if team == 1 else fx_death_no;

	fx.finished.connect(kill_ball)
	fx.visible = true;
	fx.emitting = true;

func kill_ball():
	self.queue_free();
