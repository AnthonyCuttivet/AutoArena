class_name WeaponPerfect extends Weapon

@export var sfx_fingersnap:SFX;
@export var sfx_tsk:SFX;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);
	EventBus.ball_damaged.connect(on_ball_damaged_received);

func init_scaling_stat():
	scaling_stat_value = damage;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	if(lifesteal && !lifesteal_active): return;
	damage += stat_scale_value;
	AudioManager.play_sfx(sfx_fingersnap);
	init_scaling_stat();

func on_weapon_hit_received(id:int, slot_id:int, _to:int, _is_projectile:bool):
	if(!is_valid_slot_it(id, slot_id)): return;
	scale_stat();

func on_ball_damaged_received(id:int, _amount:int, _from:int, _slot_id:int):
	if(id != ball_owner.get_instance_id()): return;
	damage = 1;
	init_scaling_stat();
	AudioManager.play_sfx(sfx_tsk);

	if(battleblock_mode):
		for key in ball_owner.claimed_blocks.keys():
			ball_owner.claimed_blocks[key] = false;

		EventBus.update_bb_blocks_ui.emit(ball_owner);

func set_battleblock_modifiers(weapon_index:int):
	super.set_battleblock_modifiers(weapon_index);
	scaling_stat_value = 2.0;
	#ball_owner.gravity_strength /= 3.5;
	ball_owner.relative_bounce_boost = 0.3;
