class_name WeaponPerfect extends Weapon

@export var sfx_fingersnap:SFX;
@export var sfx_tsk:SFX;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);
	EventBus.ball_damaged.connect(on_ball_damaged_received);

func init_scaling_stat():
	scaling_stat_value = damage;
	ball_owner.update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	if(lifesteal && !lifesteal_active): return;
	damage += stat_scale_value;
	init_scaling_stat();

func on_weapon_hit_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	scale_stat();
	AudioManager.play_sfx(sfx_fingersnap);

func on_ball_damaged_received(id:int, _amount:int, _from:int):
	if(id != ball_owner.get_instance_id()): return;
	damage = 1;
	init_scaling_stat();
	AudioManager.play_sfx(sfx_tsk);
