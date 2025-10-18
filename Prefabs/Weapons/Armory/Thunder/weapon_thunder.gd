class_name WeaponThunder extends Weapon

@export var thunders_needed:int = 2
@export var thunderstrike_prefab: PackedScene;
@export var thunderstrike_duration:float = 1.5;
@export var closed:bool = false;
@export var sfx_thunderstrike:SFX;

@onready var p_spawn: Node2D = $PSpawn

var thunders:Dictionary[int, Projectile];
var next_thunder:int = 0;

var thunderstrikes:Dictionary[int, Projectile];
var next_thunderstrike:int = 0;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_listened_event_received);

func init_scaling_stat():
	scaling_stat_value = thunderstrike_duration;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	thunderstrike_duration += stat_scale_value;
	shoot_speed += 0.015;
	init_scaling_stat();

func on_listened_event_received(id:int, slot_id:int, _to:int, _is_projectile:bool):
	if(!is_valid_slot_it(id, slot_id)): return;
	scale_stat();
	pass;

func shoot_projectile():
	add_thunder();

func add_thunder():
	var p:Projectile = Utils.shoot_projectile(settings.projectile_prefab, ball_owner, self, weapon_slot.global_rotation, self);
	p.set_speed(projectile_speed + scaling_stat_value * 50.0);
	p.weapon_owner = self;
	p.scale = weapon_slot.scale * ball_owner.root.scale * projectile_scale;
	p.global_position = p_spawn.global_position;
	p.global_rotation = p_spawn.global_rotation;
	p.sprite_2d.modulate = Color.GRAY;
	p.sprite_2d.modulate.a = 0.7;
	register_thunder(p);

	AudioManager.play_sfx(settings.sfx_shoot, "SFX");

	if(next_thunder % thunders_needed == 0):
		var t:Dictionary[int,int] = {};
		var s = [];
		for i in thunders_needed - 1:
			s.push_back(next_thunderstrike);
			t[next_thunder - (1+i)] = 0;
			t[next_thunder - (2+i)] = 0;
			add_thunderstrike(next_thunder - (2+i), next_thunder - (1+i));
			pass

		if(closed && thunders_needed > 2):
			s.push_back(next_thunderstrike);
			add_thunderstrike(next_thunder - thunders_needed, next_thunder - 1);

		get_tree().create_timer(thunderstrike_duration).timeout.connect(clear_thunderstrike.bind(t.keys(),s));


func add_thunderstrike(i0:int, i1:int):

	var p0:Vector2 = thunders[i0].global_position;
	var p1:Vector2 = thunders[i1].global_position;

	thunders[i0].velocity = Vector2.ZERO;
	thunders[i1].velocity = Vector2.ZERO;

	thunders[i0].sprite_2d.modulate = Color.WHITE;
	thunders[i1].sprite_2d.modulate = Color.WHITE;

	var pos:Vector2 = p1 + (p0 - p1) * 0.5;
	var rot:float = (p0 - p1).normalized().angle();

	var strike:ProjectileThunderStrike = Utils.spawn_projectile(thunderstrike_prefab, ball_owner, self, pos, rot, self);
	strike.weapon_owner = self;

	strike.thunderstrike_hitbox.shape.height = (p0.distance_to(p1) / 2.3);
	strike.thunderstrike_hitbox.shape.radius = 2.5;

	strike.thunderstrike_line.set_point_position(0, strike.thunderstrike_line.to_local(p0));
	strike.thunderstrike_line.set_point_position(1, strike.thunderstrike_line.to_local(p1));

	register_thundertrike(strike);

	AudioManager.play_sfx(sfx_thunderstrike);


func register_thunder(p:Projectile):
	thunders[next_thunder] = p;
	next_thunder += 1;

func register_thundertrike(p:Projectile):
	thunderstrikes[next_thunderstrike] = p;
	next_thunderstrike += 1;

func clear_thunderstrike(t, s):

	for i in t:
		if(thunders[i] != null):
			thunders[i].destroy(0);
		thunders.erase(i);
		pass

	for i in s:
		if(thunderstrikes[i] != null):
			thunderstrikes[i].destroy(0);
		thunderstrikes.erase(i);

func set_battleblock_modifiers():
	super.set_battleblock_modifiers();

	projectile_speed = 300.0;
	damage = 7;
	rotation_speed *= 1.5;
	ball_owner.gravity_strength /= 3.5;
	ball_owner.relative_bounce_boost = 0.3;
