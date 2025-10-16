class_name WeaponPipe extends Weapon

@export var kb_dmg_ratio:float = 0.001;
@export var hitstop_scale:float = 0.03;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);

func init_scaling_stat():
	scaling_stat_value = knockback;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	knockback += stat_scale_value;
	damage = knockback * kb_dmg_ratio;
	if(!battleblock_mode):
		hitstop += hitstop_scale;
	init_scaling_stat();

func on_weapon_hit_received(id:int, slot_id:int, _to:int, _is_projectile:bool):
	if(!is_valid_slot_it(id, slot_id)): return;
	scale_stat();
	pass;

func get_custom_stat_format() -> String:
	return str(damage) + " / " + str(knockback *kb_dmg_ratio) + " x";

func set_battleblock_modifiers():
	super.set_battleblock_modifiers();

	ball_owner.gravity_strength /= 3.5;
	ball_owner.relative_bounce_boost = 0.3;
