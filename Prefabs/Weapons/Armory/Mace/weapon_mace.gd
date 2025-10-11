class_name WeaponMace extends Weapon

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);

func init_scaling_stat():
	scaling_stat_value = rotation_speed;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	rotation_speed += stat_scale_value;
	if(battleblock_mode):
		damage = 1 + (Utils.get_claimed_blocks_amount(ball_owner) * 0.75);
	init_scaling_stat();

func on_weapon_hit_received(id:int, slot_id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	scale_stat();
	pass;

func set_battleblock_modifiers():
	super.set_battleblock_modifiers();

	ball_owner.gravity_strength /= 3.5;
	ball_owner.relative_bounce_boost = 0.3;
