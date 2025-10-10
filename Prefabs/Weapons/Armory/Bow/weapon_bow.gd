class_name WeaponBow extends Weapon

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_listened_event_received);

func init_scaling_stat():
	scaling_stat_value = projectiles;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	projectiles += stat_scale_value;
	shoot_duration += 0.002;
	init_scaling_stat();
	add_remaining_shoot();

func on_listened_event_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	scale_stat();
	pass;
