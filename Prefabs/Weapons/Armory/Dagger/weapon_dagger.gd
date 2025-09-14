class_name WeaponDagger extends Weapon

@export var scale_divider:float = 10.0;
@export var self_hitstop_delay:float = 0.5;

@onready var sprite_charged: Sprite2D = $Sprite2D/SpriteCharged
@onready var weapon_hitbox: Hitbox = $Sprite2D/WeaponHitbox

var no_self_hitstop:bool = false;
var ui_rot_speed:float = 0.0;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);

func init_scaling_stat():
	scaling_stat_value = rotation_speed;
	ball_owner.update_stat_text();
	set_charged_sprite_alpha();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	rotation_speed += stat_scale_value;
	attack_speed += stat_scale_value;
	ui_rot_speed += stat_scale_value * 10.0;

	init_scaling_stat();

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, _hitbox_id:int, projectile_hit:bool = false) -> void:
	if(ball_owner.is_in_same_team(other)):
		return;

	hitboxes[0].weapon_clash_cd_elapsed = hitboxes[0].weapon_clash_cd * 2.0;
	hitboxes[0].target_cd[other] = hitstop / (0.8 + (rotation_speed / scale_divider));

	if(!other.silent_on_hit):
		AudioManager.play_sfx(settings.sfx_hit, "SFX");

	var d:int = get_custom_damage_value() if custom_damage else damage;

	var kb_dist:float = knockback + other.linear_velocity.length() if !other.knockback_immune else 0.0;

	var kb:Vector2 = (other.global_position - ball_owner.global_position).normalized() * kb_dist;

	if(projectile_hit):
		kb = (hit_pos - ball_owner.global_position).normalized() * kb_dist;

	other.affect_health(-d, ball_owner);

	if(!projectile_hit && !no_self_hitstop):
		ball_owner.start_hitstop(0.0, hitstop);
		no_self_hitstop = true;
		get_tree().create_timer(hitstop + self_hitstop_delay).timeout.connect(func(): no_self_hitstop = false);

	other.start_hitstop(0.0, hitstop, kb);
	other.hitflash(hitstop);
	other.hit_pos = hit_pos;

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), other.get_instance_id(), projectile_hit);
	pass;

func on_weapon_hit_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	scale_stat();
	pass;

func get_custom_stat_format() -> String:
	return Utils.format_float(attack_speed * 3.0);

func set_charged_sprite_alpha():
	sprite_charged.self_modulate.a = clamp(((rotation_speed - 3.0)), 0,1);

func set_battleblock_modifiers():
	super.set_battleblock_modifiers();
	ball_owner.gravity_strength /= 3.5;
	ball_owner.relative_bounce_boost = 0.3;
	ball_owner.weapon.hitstop /= 0.2;
	attack_speed = 2.0;

