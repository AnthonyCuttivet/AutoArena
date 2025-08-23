class_name WeaponHydra extends Weapon

@export var heads_colors:Array[Color];
@export var spawn_head_each_hp_lost:int;
@export var heads:Array[WeaponHydraHead];
@export var heads_projectiles:Array[PackedScene];
@export var heads_shoot_delay:Array[float];
@export var head_prefab:PackedScene;
@export var heads_root:Node2D;
@export var head_offset:float;
@export var heads_angle:float = 60.0;
@export var sfxs_shoot:Array[SFX];
@export var sfxs_hit:Array[SFX];

var next_head_at_hp:int = 0;
var next_head_side:int = 1;

var shooted_projectile:Projectile = null;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);
	EventBus.ball_damaged.connect(on_ball_damaged_received);

func init(s:WeaponSettings, owner:BattleBall):
	super.init(s, owner);
	add_head();
	next_head_at_hp = ball_owner.health - spawn_head_each_hp_lost;

func init_scaling_stat():
	scaling_stat_value = damage;
	ball_owner.update_stat_text();

func scale_stat():
	damage += stat_scale_value;
	init_scaling_stat();

func shoot_projectile():
	for head in heads:
		if(head.can_shoot((1.0 / shoot_speed))):
			AudioManager.play_sfx(head.sfx_shoot, "SFX");
			shooted_projectile = Utils.shoot_projectile(head.projectile, ball_owner, head.global_rotation, head.sprite_2d);
			shooted_projectile.weapon_owner = head;

func get_custom_damage_value() -> int:
	return damage / heads.size();

func on_weapon_hit_received(id:int, to:int, is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	if(is_projectile):
		scale_stat();
	pass;

func on_ball_damaged_received(id:int, amount:int, from:int):
	if(id != ball_owner.get_instance_id()): return;

	if(ball_owner.health <= next_head_at_hp):
		add_head();
		next_head_at_hp -= spawn_head_each_hp_lost;

func add_head():
	var new_head:WeaponHydraHead = spawn_head();
	new_head.init(settings, ball_owner);
	heads.append(new_head);

	for i in heads.size():
		set_head_posrot(i);
		pass
	pass;

func spawn_head() -> WeaponHydraHead:
	var head:WeaponHydraHead = head_prefab.instantiate();
	var heads_count:int = heads.size();
	head.sprite_2d.self_modulate = heads_colors[heads_count % heads_colors.size()];
	head.projectile = heads_projectiles[heads_count % heads_projectiles.size()];
	head.shoot_delay = heads_shoot_delay[heads_count % heads_shoot_delay.size()];
	head.sfx_shoot = sfxs_shoot[heads_count % sfxs_shoot.size()];
	head.sfx_hit = sfxs_hit[heads_count % sfxs_hit.size()];
	heads_root.add_child(head);
	return head;

func set_head_posrot(i:int):
	var head:WeaponHydraHead = heads[i];
	var even:bool = heads.size() % 2 == 0;

	if(even):
		head.global_rotation_degrees = (i * heads_angle * next_head_side) + heads[0].global_rotation_degrees;
	else:
		if(i > 0):
			if(i % 2 == 0):
				i = i / 2;
			else:
				i = (i*2) - 1;

		head.global_rotation_degrees = (i * heads_angle * next_head_side) + heads[0].global_rotation_degrees;

	next_head_side *= -1;

	head.position = head.transform.x * head_offset;
