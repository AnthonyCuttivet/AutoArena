class_name WeaponKatana extends Weapon

@export var parries_needed:int = 4;
@export var hitstop_multiplier:float = 0.4;

@onready var sprite_charged: Sprite2D = $Sprite2D/SpriteCharged

var parries_count:int = 0;
var base_damage:int = 1;
var tmp_damage:int = 0;

var bb_damage:int = 0;

func _init() -> void:
	EventBus.ball_weapon_clash.connect(on_weapon_clash_received);
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);

func init_scaling_stat():
	scaling_stat_value = damage;
	update_stat_text();
	set_charged_sprite_alpha();

func scale_stat_block(force:bool):
	if(force):
		bb_damage = Utils.get_claimed_blocks_amount(ball_owner);

	damage += 1.0 if force else stat_scale_value;
	init_scaling_stat();

func scale_stat(force:bool = false):
	if(no_stat_scale):
		scale_stat_block(force);
		return;

	if(no_stat_scale && !force): return;
	damage += stat_scale_value;
	init_scaling_stat();

func on_weapon_hit_received(id:int, slot_id:int, to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id() || slot_id != weapon_slot_id): return;

	damage = 1 if !battleblock_mode else 1 + bb_damage;
	init_scaling_stat();
	pass;

func on_weapon_clash(other:Node2D, clash_pos:Vector2, projectile_hit:bool = false, silent:bool = false, force:bool = false):
	if(!silent):
		AudioManager.play_sfx(settings.sfx_clash, "SFX");

	var kb:Vector2 = Vector2.ZERO;

	if(!projectile_hit):
		kb = (ball_owner.position - other.position).normalized() * ball_owner.max_speed;
		reverse_rotation();

	ball_owner.start_hitstop_clash(0.0, 0.15, kb, other);
	EventBus.ball_weapon_clash.emit(ball_owner.get_instance_id(), weapon_slot_id, clash_pos, silent);

	if(battleblock_mode && ball_owner.main.get_ball_by_id(other.get_instance_id()) != null):
		scale_stat_block(false);
	pass;

func on_weapon_clash_received(id:int, slot_id:int, _clash_pos:Vector2, _silent:bool):
	if(!is_valid_slot_it(id, slot_id)): return;
	scale_stat();
	pass;

# func get_custom_stat_format() -> String:
# 	return str(base_damage + tmp_damage) + " (" + str(base_damage) + ")";

func set_charged_sprite_alpha():
	sprite_charged.self_modulate.a = clamp(((damage - 1) / 10.0), 0,1);

func set_battleblock_modifiers():
	super.set_battleblock_modifiers();
	ball_owner.gravity_strength /= 3.5;
	ball_owner.relative_bounce_boost = 0.3;
