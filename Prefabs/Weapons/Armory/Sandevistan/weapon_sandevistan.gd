class_name WeaponSandevistan extends Weapon

@export var just_hurt_hit_cd:float = 0.2;
@export var multi_hit_cd:float = 1.0;
@export var sandevistan_hp_lost_per_s:int = 2;
@export var speed_scale:float = 150.0;
@export var sandevistan_damage_threshold:int = 10;
@export var sandevistan_trigger_delay:float = 0.5;
@export var sandevistan_trigger_time_scale:Array[float];
@export var sandevistan_name_color:Color;
@export var psychosis_details_color:Color;
@export var afterimages_opacity:Array[float];
@export var afterimages_interval:Array[float];
@export var sfx_sandevistan_hit:SFX;
@export var sfx_sandevistan_trigger:SFX;

var fdamage:float = 1.0;
var current_damage:int = 1;
var base_max_speed:float = 0.0;
var can_hit_cd_remaining:float = 0.0;
var sandevistan_active_remaining:float = 0.0;
var sandevistan_active:bool = false;
var next_sandevistan_trigger:int = 0;
var limiter_remaining:float = 0.0;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);
	EventBus.ball_damaged.connect(on_damaged);
	EventBus.ball_bounce_other_ball.connect(on_ball_bounced_other_ball);
	EventBus.ball_bounce_battleblock.connect(on_ball_bounced_battleblock);

func init(s:WeaponSettings, o:BattleBall) -> void:
	super.init(s, o);
	base_max_speed = o.max_speed;
	ball_owner.afterimage.active = true;
	next_sandevistan_trigger = sandevistan_damage_threshold;

func init_scaling_stat():
	scaling_stat_value = fdamage;
	ball_owner.update_stat_text(true);

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	fdamage += stat_scale_value;
	ball_owner.max_speed += (speed_scale * stat_scale_value);
	init_scaling_stat();

	if(limiter_remaining == 0.0):
		limiter_remaining = sandevistan_trigger_delay;

func _process(delta: float) -> void:
	if(ball_owner.main == null): return;

	delta *= ball_owner.physics_time_scale;

	if(limiter_remaining > 0.0):
		limiter_remaining = clamp(limiter_remaining - delta, 0, 100.0);

	if(!can_hit()):
		can_hit_cd_remaining = clamp(can_hit_cd_remaining - delta, 0.0, 100.0);

	if(sandevistan_active_remaining > 0.0):
		sandevistan_active_remaining = clamp(sandevistan_active_remaining - delta, 0.0, 100.0);
		if(sandevistan_active_remaining == 0.0):
			sandevistan_mode(false);

	current_damage = clamp((ball_owner.linear_velocity.length() - base_max_speed) / speed_scale, 1, floor(fdamage));

	if(current_damage == floor(fdamage) && limiter_remaining > 0.0):
		current_damage -= 1;

	if(battleblock_mode):
		current_damage += settings.base_damage_multiplier;

	ball_owner.update_stat_text();

	# print("Limiter : " + str(limiter_remaining));
	# print(current_damage >= sandevistan_damage_threshold, current_damage == floor(fdamage), current_damage >= next_sandevistan_trigger);
	# print(str(current_damage) + " - "  + str(sandevistan_damage_threshold) + " - " + str(floor(fdamage)) + " - " + str(next_sandevistan_trigger));

	if(current_damage >= sandevistan_damage_threshold && current_damage == floor(fdamage) && current_damage >= next_sandevistan_trigger):
		sandevistan_mode(true);

func sandevistan_mode(s:bool):
	sandevistan_active = s;
	ball_owner.afterimage.setup_afterimages(s, afterimages_interval[int(s)], afterimages_opacity[int(s)]);
	ball_owner.afterimage.spawn_interval /= float(next_sandevistan_trigger);
	ball_owner.afterimage.continuous = !s;

	ball_owner.set_hp_lost_per_s(0 if !s else sandevistan_hp_lost_per_s);
	# ball_owner.aled = s;

	if(s):
		next_sandevistan_trigger = current_damage + 1;
		sandevistan_active_remaining = sandevistan_trigger_time_scale[0] * sandevistan_trigger_time_scale[1];
		AudioManager.play_sfx(sfx_sandevistan_trigger, "SFX");
		ball_owner.drag_force = 0.01;
		ball_owner.set_physics_time_scale(1.0 + sandevistan_trigger_time_scale[0], sandevistan_trigger_time_scale[1]);
		ball_owner.main.set_time_scale(sandevistan_trigger_time_scale[0], sandevistan_trigger_time_scale[1]);

	settings.name = "UNARMED?" if !s else sandevistan_name();
	settings.details = sandevistan_details() if !s else cyberpsychosis_details();
	ball_owner.update_ui_name(ball_owner.color if !s else sandevistan_name_color);
	ball_owner.update_ui_details(ball_owner.color if !s else psychosis_details_color, true);

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, _hitbox_id:int, projectile_hit:bool = false) -> void:
	# if(other.linear_velocity.length() > ball_owner.linear_velocity.length() && !sandevistan_active):
	# 	scale_stat();
	# 	return;

	if(!can_hit()): return;

	if(other.is_invincible()):
		return;

	if(ball_owner.is_in_same_team(other)):
		return;

	if(sandevistan_active):
		ball_owner.drag_force = ball_owner.base_drag_force;

	if(!other.silent_on_hit):
		AudioManager.play_sfx(settings.sfx_hit if !sandevistan_active else sfx_sandevistan_hit, "SFX");

	var kb_dist:float = (knockback * (1.0 + (current_damage / 15.0))) + other.linear_velocity.length() if !other.is_boss else 0.0;
	var kb:Vector2 = (other.global_position - ball_owner.global_position).normalized() * kb_dist;
	var h:float = hitstop + (current_damage / 50.0);

	if(projectile_hit):
		kb = (hit_pos - ball_owner.global_position).normalized() * kb_dist;

	other.affect_health(-current_damage, ball_owner);

	ball_owner.start_hitstop(0.01, h);

	other.start_hitstop(0.0, h, kb);
	other.hitflash(hitstop);
	other.hit_pos = hit_pos;

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), other.get_instance_id(), projectile_hit);

	if(sandevistan_active):
		EventBus.set_chromatic_aberration.emit(3.0, 0.15);

	can_hit_cd_remaining += multi_hit_cd;

	pass;

func on_damaged(id:int, _amount:int, _from:int):
	if(id != ball_owner.get_instance_id()): return;
	can_hit_cd_remaining += just_hurt_hit_cd;
	ball_owner.linear_velocity = ball_owner.linear_velocity.normalized() * base_max_speed;

func on_ball_bounced_other_ball(id:int, other:int):
	if(!can_hit): return;
	if(id != ball_owner.get_instance_id()): return;

	var other_ball:BattleBall = ball_owner.main.get_ball_by_id(other);

	if(other_ball.team == ball_owner.team): return;

	on_weapon_hit(other_ball, other_ball.global_position, hitboxes[0].get_instance_id());

	pass;

func on_ball_bounced_battleblock(id:int, block:MCBattleBlock):
	if(!can_hit): return;
	if(id != ball_owner.get_instance_id()): return;

	on_weapon_hit(block.hurtbox.ball_owner, block.global_position, hitboxes[0].get_instance_id());

	pass;

func can_hit() -> bool:
	return can_hit_cd_remaining <= 0.0;

func on_weapon_hit_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	scale_stat();
	pass;

func get_custom_stat_format() -> String:
	return str(current_damage) + " / " + Utils.format_float(fdamage,1);

func sandevistan_name() -> String:
	return "[wave amp=50.0 freq=1 connected=1][color=#FF4D00]S[/color][color=#F25C33]A[/color][color=#E56C66]N[/color][color=#D97C99]D[/color][color=#CC8CCC]E[/color][color=#C09CFF]V[/color][color=#B1AEFE]I[/color][color=#A3C1FD]S[/color][color=#95D4FD]T[/color][color=#87E7FC]A[/color][color=#79FAFC]N[/color][/wave]"

func sandevistan_details() -> String:
	return "Triggers at " + str(next_sandevistan_trigger) + " / " + str(next_sandevistan_trigger) + " Speed";

func cyberpsychosis_details() -> String:
	return "CYBERPSYCHOSIS: -" + str(sandevistan_hp_lost_per_s) + "hp/s";

func set_battleblock_modifiers():
	super.set_battleblock_modifiers();

	ball_owner.gravity_strength /= 3.5;
	ball_owner.relative_bounce_boost = 0.3;
