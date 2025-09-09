class_name WeaponKatana extends Weapon

@export var parries_needed:int = 4;

@onready var sprite_charged: Sprite2D = $Sprite2D/SpriteCharged

var parries_count:int = 0;
var base_damage:int = 1;
var tmp_damage:int = 0;

func _init() -> void:
	EventBus.ball_weapon_clash.connect(on_weapon_clash_received);
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);

func init_scaling_stat():
	scaling_stat_value = damage;
	ball_owner.update_stat_text();
	set_charged_sprite_alpha();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	# parries_count += 1;

	# if(parries_count == parries_needed):
	# 	parries_count = 0;
	# 	base_damage += 1;

	# tmp_damage += stat_scale_value;
	damage += 3;
	init_scaling_stat();

func on_weapon_hit_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	damage = 1;
	# tmp_damage = 0;
	init_scaling_stat();
	pass;

func on_weapon_clash(other:Node2D, clash_pos:Vector2, projectile_hit:bool = false):
	AudioManager.play_sfx(settings.sfx_clash, "SFX");

	var kb:Vector2 = Vector2.ZERO;

	if(!projectile_hit):
		kb = (ball_owner.position - other.position).normalized() * ball_owner.max_speed;
		reverse_rotation();

	ball_owner.start_hitstop(0.0, 0.15, kb);
	EventBus.ball_weapon_clash.emit(ball_owner.get_instance_id(), clash_pos);
	scale_stat();
	pass;

func on_weapon_clash_received(id:int, _clash_pos:Vector2):
	if(id != ball_owner.get_instance_id()): return;
	# scale_stat();
	pass;

# func get_custom_stat_format() -> String:
# 	return str(base_damage + tmp_damage) + " (" + str(base_damage) + ")";

func set_charged_sprite_alpha():
	sprite_charged.self_modulate.a = clamp(((damage - 1) / 10.0), 0,1);
