class_name ProjectilePlume extends Projectile

@export var acceleration_curve:Curve;
@export var rot_lerp_speed:float = 5.0;
@export var collision_shape_recall: CollisionShape2D
@export var collision_shape_shoot: CollisionShape2D

@onready var trail: Trail2D = $Trail

var move_duration:float = 0.0;
var recall_duration:float = 0.0;
var damaging:bool = true;
var move_elapsed:float = 0.0;
var recall_elapsed:float = 0.0;
var fixed_dir:Vector2 = Vector2.ZERO;
var position_fixed:bool = false;
var recalling:bool = false;

func init(o:BattleBall, s:float, _p:int = 0, _b:int = 0):
	super.init(o, s);

	fixed_dir = transform.x;
	collision_shape_recall.set_deferred("disabled", true);

func _physics_process(delta: float) -> void:
	move_elapsed += delta;

	#var r:float = move_elapsed / move_duration;

	damaging = !position_fixed;

	if(!position_fixed && !recalling && raycast.is_colliding() && raycast.get_collider().is_in_group("WALL")):
		position_fixed = true;
		trail.set_active(true);

	if(position_fixed || recalling):
		var rot_to_owner:Vector2 = (ball_owner.global_position - global_position).normalized();
		global_rotation = Utils.smooth_rotation(global_rotation, rot_to_owner.angle(), rot_lerp_speed, delta);

	if(!position_fixed):
		# global_position += Utils.sample_curve(acceleration_curve, r) * fixed_dir * speed * delta;
		global_position += fixed_dir * speed * delta;

	if(self_destruct_remaining > 0.0):
		self_destruct_remaining = clamp(self_destruct_remaining - delta, 0.0, 100.0);
		if(self_destruct_remaining == 0.0):
			destroy();

	pass;

func _on_projectile_hitbox_area_entered(other: Area2D) -> void:
	if(!damaging): return;
	if(other is not Hurtbox): return;

	if(recalling && other.ball_owner == ball_owner):
		destroy();
		return;

	if(other.ball_owner != ball_owner):
		on_hurtbox_hit(other.ball_owner);

func _on_projectile_hitbox_body_entered(other: Node2D) -> void:
	if(absolute) : return;

	if(other.is_in_group("DEADZONE")):
		destroy();
		return;

func recall():
	absolute = true;
	recalling = true;
	speed = global_position.distance_to(ball_owner.global_position) / recall_duration;
	rot_lerp_speed *= 5.0;
	fixed_dir = (ball_owner.global_position - global_position).normalized();
	position_fixed = false;
	move_elapsed = 0.0;
	move_duration = recall_duration;
	self_destruct_remaining = recall_duration * 1.1;

	collision_shape_recall.set_deferred("disabled", false);
	collision_shape_shoot.set_deferred("disabled", true);

	# DebugDraw2D.arrow_vector(global_position, fixed_dir * global_position.distance_to(ball_owner.global_position), Color.PURPLE, 2.0, recall_duration);
	pass;
