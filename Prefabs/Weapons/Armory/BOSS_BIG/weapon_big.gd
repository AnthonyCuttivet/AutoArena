class_name WeaponBIG extends Weapon

@export var double_scale_each_hp_lost:int;

var next_scale_at_hp:int = 0;
var weapon:Weapon = null;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);
	EventBus.ball_damaged.connect(on_ball_damaged_received);

func init(s:WeaponSettings, o:BattleBall):
	settings = o.main.all_weapons[o.dual_wield[0]];
	settings.name = "B.I.G";
	settings.details = s.details;

	settings.base_rotation_speed *= 0.75;
	settings.base_attack_speed *= 0.65;
	settings.base_shoot_speed *= 0.65;
	settings.max_speed *= 0.75;
	settings.min_horizontal = 50.0;
	settings.bounce_boost = 0.0;
	settings.relative_bounce_boost = 0.25;

	weapon = o.spawn_weapon(settings, o.weapon_slots[0], 0);
	o.weapons.pop_front();

	sprite_2d.texture = weapon.sprite_2d.texture;
	sprite_2d.visible = false;

	o.weapon_settings = settings;
	o.fill_values_from_weapon_settings();
	o.set_ball_color();

	super.init(settings, o);

	next_scale_at_hp = ball_owner.health - double_scale_each_hp_lost;

func init_scaling_stat():
	scaling_stat_value = damage;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	# damage += stat_scale_value;
	init_scaling_stat();

func on_weapon_hit_received(id:int, _slot_id:int, _to:int, is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	if(is_projectile):
		scale_stat();
	pass;

func on_ball_damaged_received(id:int, _amount:int, _from:int, _slot_id:int):
	if(id != ball_owner.get_instance_id()): return;

	if(ball_owner.health <= next_scale_at_hp):
		next_scale_at_hp -= double_scale_each_hp_lost;
		ball_owner.weapon_slots[0].position.x = 0.0;
		grow_gamefeel();

func grow_gamefeel() -> void:
	# Tween back smoothly
	clash_tween = create_tween();
	clash_tween.tween_property(ball_owner.weapon_slots[0], "scale", ball_owner.weapon_slots[0].scale * 1.15, 0.15).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_IN);
