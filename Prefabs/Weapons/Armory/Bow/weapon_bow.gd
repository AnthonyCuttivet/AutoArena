class_name WeaponBow extends Weapon

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_listened_event_received);

func init_scaling_stat():
	scaling_stat_value = projectiles;
	ball_owner.update_stat_text();

func scale_stat():
	projectiles += stat_scale_value;
	init_scaling_stat();
	add_remaining_shoot();

func on_listened_event_received(id:int):
	if(id != ball_owner.get_instance_id()): return;
	scale_stat();
	pass;
