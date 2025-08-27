class_name WeaponUnarmed extends Weapon

@export var just_hurt_hit_cd:float = 0.2;
@export var multi_hit_cd:float = 1.0;
@export var speed_scale:float = 150.0;
@export var afterimages_opacity:float = 0.75;
@export var afterimages_interval:float = 0.05;

var fdamage:float = 1.0;
var current_damage:int = 1;
var base_max_speed:float = 0.0;
var can_hit_cd_remaining:float = 0.0;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);
	EventBus.ball_damaged.connect(on_damaged);
	EventBus.ball_bounce_other_ball.connect(on_ball_bounced_other_ball);

func init(s:WeaponSettings, o:BattleBall) -> void:
	super.init(s, o);
	base_max_speed = o.max_speed;
	ball_owner.afterimage.active = true;
	ball_owner.afterimage.setup_afterimages(false, afterimages_interval, afterimages_opacity);

func init_scaling_stat():
	scaling_stat_value = fdamage;
	ball_owner.update_stat_text(true);

func scale_stat():
	fdamage += stat_scale_value;
	ball_owner.max_speed += (speed_scale * stat_scale_value);
	init_scaling_stat();

func _process(delta: float) -> void:
	if(ball_owner.main == null): return;

	delta *= ball_owner.physics_time_scale;

	if(!can_hit()):
		can_hit_cd_remaining = clamp(can_hit_cd_remaining - delta, 0.0, 100.0);

	current_damage = clamp((ball_owner.linear_velocity.length() - base_max_speed) / speed_scale, 1, floor(fdamage));

	ball_owner.update_stat_text(true);

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, _hitbox_id:int, projectile_hit:bool = false) -> void:
	# if(other.linear_velocity.length() > ball_owner.linear_velocity.length()):
	# 	scale_stat();
	# 	return;

	#if(other.aled):
		#return;

	if(!can_hit()): return;

	if(other.is_invincible()):
		return;

	if(ball_owner.is_in_same_team(other)):
		return;

	AudioManager.play_sfx(settings.sfx_hit, "SFX");

	var kb_dist:float = (knockback * (1.0 + (current_damage / 15.0))) + other.linear_velocity.length() if !other.is_boss else 0.0;
	var kb:Vector2 = (other.global_position - ball_owner.global_position).normalized() * kb_dist;
	var h:float = hitstop + (current_damage / 50.0);

	if(projectile_hit):
		kb = (hit_pos - ball_owner.global_position).normalized() * kb_dist;

	other.affect_health(-current_damage, ball_owner);

	ball_owner.start_hitstop(0.01, h, (ball_owner.global_position - other.global_position).normalized() * 800.0);

	other.start_hitstop(0.0, h, kb);
	other.hitflash(hitstop);
	other.hit_pos = hit_pos;

	ball_owner.linear_velocity = ball_owner.linear_velocity.normalized() * ball_owner.base_max_speed;

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), other.get_instance_id(), projectile_hit);

	can_hit_cd_remaining += multi_hit_cd;

	pass;

func on_damaged(id:int, _amount:int, _from:int):
	if(id != ball_owner.get_instance_id()): return;
	can_hit_cd_remaining += just_hurt_hit_cd;
	ball_owner.linear_velocity = ball_owner.linear_velocity.normalized() * 100.0;

func on_ball_bounced_other_ball(id:int, other:int):
	if(!can_hit): return;
	if(id != ball_owner.get_instance_id()): return;

	var other_ball:BattleBall = ball_owner.main.get_ball_by_id(other);

	if(other_ball.team == ball_owner.team): return;

	on_weapon_hit(other_ball, other_ball.global_position, hitboxes[0].get_instance_id());

	pass;

func can_hit() -> bool:
	return can_hit_cd_remaining <= 0.0;

func on_weapon_hit_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	scale_stat();
	pass;

func get_custom_stat_format() -> String:
	return str(current_damage) + " / " + Utils.format_float(fdamage,1);
