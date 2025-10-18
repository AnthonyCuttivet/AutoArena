class_name WeaponQiang extends Weapon

@export var hitbox_low:Hitbox;
@export var hitbox_high:Hitbox;
@export var tipper_hitstop_multiplier:float = 1.5;
@export var tipper_sfx:SFX;
@export var tipper_damage:int = 10;
@export var low_hit_delay:float = 0.5;
@export var non_tipper_dmg:float = 0.2;

var last_low_hit:int = 0;
var last_tipper:int = 0;

func init_scaling_stat():
	scaling_stat_value = tipper_damage;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	tipper_damage += stat_scale_value;
	init_scaling_stat();

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, hitbox_id:int, projectile_hit:Projectile = null, silent:bool = false) -> void:
	if(ball_owner.is_in_same_team(other)):
		return;

	if(hitbox_id == hitbox_low.get_instance_id()):
		last_low_hit = Time.get_ticks_msec();

	if(hitbox_id == hitbox_high.get_instance_id()):
		if(Time.get_ticks_msec() - last_low_hit < low_hit_delay * 1000):
			return;
		if(Time.get_ticks_msec() - last_tipper < low_hit_delay * 3000):
			return;
		last_tipper = Time.get_ticks_msec();

	var tipper:bool = hitbox_id == hitbox_high.get_instance_id();

	var d:int = get_custom_damage_value() if custom_damage else damage;
	var h:float = hitstop;

	if(tipper):
		d = int(scaling_stat_value);
		h *= tipper_hitstop_multiplier;
		if(!other.silent_on_hit):
			AudioManager.play_sfx(tipper_sfx, "SFX");
		scale_stat();
	else:
		d = max(1.0, floor(scaling_stat_value * non_tipper_dmg));
		if(!other.silent_on_hit):
			AudioManager.play_sfx(settings.sfx_hit, "SFX");

	var kb:Vector2 = (other.global_position - ball_owner.global_position).normalized() * other.max_speed;

	if(projectile_hit):
		kb = Vector2.ZERO;

	other.affect_health(-d, ball_owner, weapon_slot_id);

	if(!projectile_hit):
		ball_owner.start_hitstop(0.01, h, Vector2.ZERO, true, true);

	other.start_hitstop(0.00, h, kb, true, true);
	other.hitflash(h);
	other.hit_pos = hit_pos;

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), weapon_slot_id, other.get_instance_id(), projectile_hit != null);
	pass;

func set_battleblock_modifiers():
	super.set_battleblock_modifiers();

	ball_owner.gravity_strength /= 3.5;
	ball_owner.relative_bounce_boost = 0.3;
