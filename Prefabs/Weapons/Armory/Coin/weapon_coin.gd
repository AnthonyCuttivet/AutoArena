class_name WeaponCoin extends Weapon

@export var railgun_duration_scale:float = 0.5;
@export var railgun_hitstop:float = 0.2;
@export var railgun_duration:float = 0.2;
@export var railgun_prefab:PackedScene;
@export var coins_sprites:Array[Texture2D];
@export var flat_coin:Texture2D;
@export var phantom_coin:Texture2D;
@export var coin_flip_rot_speed:Vector2 = Vector2(720.0, 1080.0);
@export var coin_flip_scale:float = 1.3;
@export var base_coin_tx:Texture2D;
@export var collider:CollisionShape2D;

@export var sfx_railgun:SFX;
@export var sfx_coin_hit:SFX;
@export var sfx_coin_bounce:SFX;
@export var sfx_coin_catch:SFX;

var can_shoot:bool = true;
var active_coin:ProjectileCoin = null;
var active_railgun:ProjectileRailgun = null;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_listened_event_received);

# func _process(_delta: float) -> void:
# 	if(active_coin != null):
# 		var dir_to_center:Vector2 = (ball_owner.main.arena_center.global_position - ball_owner.global_position).normalized();
# 		var angle_between_deg:float = rad_to_deg(ball_owner.weapon_slot.global_transform.x.angle_to(dir_to_center));

# 		if(abs(angle_between_deg) > 45.0):
# 			custom_rot_speed_multiplier = 3.0;
# 		else:
# 			custom_rot_speed_multiplier = 1.0;


func init_scaling_stat():
	scaling_stat_value = projectiles;
	ball_owner.update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;

	if(active_coin != null):
		if(active_coin.gravity_force == 0.0):
			damage += 1;
		else:
			railgun_duration += railgun_duration_scale;

	if(active_railgun != null && !active_railgun.has_scaled_stat):
		active_railgun.has_scaled_stat = true;
		damage += 1;

	init_scaling_stat();

func on_listened_event_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	scale_stat();
	pass;

func shoot_projectile():
	if(active_railgun != null): return;
	set_can_shoot(false);

	var coin:ProjectileCoin = super.shoot_projectile();
	active_coin = coin;
	coin.custom_hit_sfx = sfx_coin_hit;
	coin.global_rotation = PI;
	coin.coin_parent = self;
	coin.rotation_speed = randf_range(coin_flip_rot_speed.x, coin_flip_rot_speed.y) * (1 if randf() >= 0.5 else -1);
	coin.sprite_2d.texture = flat_coin;
	coin.sprite_2d.scale *= coin_flip_scale;
	coin.velocity = ball_owner.transform.x * coin.velocity.length();

func on_coin_caught():
	# print(Utils.pf() + " Caught coin");
	AudioManager.play_sfx(sfx_coin_catch, "SFX");

	set_can_shoot(false);
	active_coin = null;
	ball_owner.start_hitstop(0.0, railgun_duration + 0.5, Vector2.ZERO, true, true);

	var railgun:ProjectileRailgun = Utils.spawn_projectile(railgun_prefab, ball_owner, ball_owner.global_position, ball_owner.weapon_slot.global_rotation, ball_owner.main);
	active_railgun = railgun;
	railgun.weapon_owner = self;
	railgun.custom_damage = 1;
	railgun.custom_hitstop = railgun_hitstop;

func set_can_shoot(s:bool):
	if(s && active_railgun != null): return;
	can_shoot = s;
	sprite_2d.texture = phantom_coin if !s else base_coin_tx;
	sprite_2d.self_modulate.a = 0.2 if !s else 1.0;

	collider.set_deferred("disabled", !s);

func on_bb_death():
	if(active_coin != null):
		active_coin.queue_free();

	if(active_railgun != null):
		active_railgun.queue_free();

func get_custom_stat_format() -> String:
	return str(damage) + " ⟐ " + str(railgun_duration) + " s";
