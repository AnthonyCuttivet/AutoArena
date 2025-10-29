class_name WeaponTitan extends Weapon

@export var bonus_rock_each_hp_lost:int;
@export var max_rocks:int = 3;
@export var shards_per_rock:int = 8;
@export var rock_inactive_for:float = 1.0;
@export var rock_prefab:PackedScene;
@export var shard_projectile_prefab:PackedScene;

var next_bonus_rock_at_hp:int = 0;
var active_rocks:Array[ProjectileTitanRock];

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);
	EventBus.ball_damaged.connect(on_ball_damaged_received);

func init(s:WeaponSettings, o:BattleBall):
	super.init(s, o);
	# add_head();
	next_bonus_rock_at_hp = ball_owner.health - bonus_rock_each_hp_lost;

func init_scaling_stat():
	scaling_stat_value = damage;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	# damage += stat_scale_value;
	init_scaling_stat();

func shoot_projectile():
	if(active_rocks.size() >= max_rocks): return;

	# AudioManager.play_sfx(head.sfx_shoot, "SFX");
	var rock:ProjectileTitanRock = Utils.spawn_projectile(rock_prefab, ball_owner, self, global_position, ball_owner.global_rotation, self);
	rock.weapon_owner = self;
	rock.hitbox.weapon = self;
	rock.inactive_for = rock_inactive_for;
	rock.scale = weapon_slot.scale * ball_owner.root.scale * projectile_scale;
	active_rocks.push_back(rock);

func on_weapon_hit_received(id:int, slot_id:int, _to:int, is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	if(is_projectile):
		scale_stat();
	pass;

func on_ball_damaged_received(id:int, _amount:int, _from:int, _slot_id:int):
	if(id != ball_owner.get_instance_id()): return;

	if(ball_owner.health <= next_bonus_rock_at_hp):
		next_bonus_rock_at_hp -= bonus_rock_each_hp_lost;
		max_rocks += 1;

func on_rock_destroyed(rock:ProjectileTitanRock):
	active_rocks.erase(rock);
	get_tree().create_timer(0.1).timeout.connect(rock.destroy);

	for i in shards_per_rock:
		var s:Projectile = Utils.shoot_projectile(shard_projectile_prefab, ball_owner, self, i * deg_to_rad(360.0 / shards_per_rock), rock, projectile_speed, 999);
		s.set_deferred("scale", s.scale * projectile_scale);
		s.weapon_owner = self;
		pass

	pass;
