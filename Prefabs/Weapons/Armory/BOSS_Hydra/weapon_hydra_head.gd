class_name WeaponHydraHead extends Weapon

@export var projectile:PackedScene;
@export var shoot_delay:float;
@export var sfx_shoot:SFX;
@export var sfx_hit:SFX;

var shoot_delay_remaining:float;
var p_scale:float;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);
	EventBus.ball_damaged.connect(on_ball_damaged_received);

	shoot_delay_remaining = shoot_delay;

func init_scaling_stat():
	scaling_stat_value = rotation_speed;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	rotation_speed += stat_scale_value;
	init_scaling_stat();

func on_weapon_hit_received(id:int, slot_id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	AudioManager.play_sfx(ball_owner.weapon.settings.sfx_hit, "SFX");
	pass;

func on_ball_damaged_received(id:int, _amount:int, _from:int, _slot_id:int):
	if(id != ball_owner.get_instance_id()): return;

func can_shoot(dt:float) -> bool:
	shoot_delay_remaining -= dt;

	if(shoot_delay_remaining <= 0):
		shoot_delay_remaining = shoot_delay;
		return true;

	return false;

func get_custom_damage_value() -> int:
	return ball_owner.weapon.heads.size();
