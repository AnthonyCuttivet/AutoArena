class_name WeaponArcanist extends Weapon

@export var thunders_needed:int = 2
@export var thunderstrike_prefab: PackedScene;
@export var thunderstrike_duration:float = 1.5;
@export var closed:bool = false;
@export var sfx_thunderstrike:SFX;
@export var spawn_thunder_each_hp_lost:int;
@export var rotating_spark_prefab:PackedScene;
@export var rotating_dist:float = 100.0;
@export var rotating_speed:float = 20.0;
@export var rotating_sparks:Array[BlackRedSpark];
@export var rotating_sparks_parent: Node2D;

@onready var p_spawn: Node2D = $PSpawn

var next_thunder_at_hp:int = 0;
var thunders:Dictionary[int, Projectile];
var next_thunder:int = 0;

var thunderstrikes:Dictionary[int, Projectile];
var next_thunderstrike_at:int = 0;

var increase_after_next:bool = false;
var scaled_at:int = 0;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_listened_event_received);
	EventBus.ball_damaged.connect(on_ball_damaged_received);

func _process(delta: float) -> void:
	rotating_sparks_parent.global_rotation_degrees += rotating_speed * delta;

	if(ball_owner.health <= 0 && thunders.size() > 0):
		for t in thunders.values():
			t.queue_free();

		thunders.clear();

func init(s:WeaponSettings, o:BattleBall):
	super.init(s, o);
	next_thunder_at_hp = ball_owner.health - spawn_thunder_each_hp_lost;
	next_thunderstrike_at = thunders_needed;

	shoot_speed = settings.base_shoot_speed / thunders_needed;
	shoot_speed_elapsed = (1 / shoot_speed);

	rotating_sparks_parent.position.x -= settings.offset;
	arrange_rotating_sparks();

func init_scaling_stat():
	scaling_stat_value = damage;
	ball_owner.update_stat_text();

func scale_stat():
	damage += stat_scale_value;
	init_scaling_stat();

func on_listened_event_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	if(scaled_at == next_thunderstrike_at): return;
	scaled_at = next_thunderstrike_at;
	scale_stat();
	pass;

func on_ball_damaged_received(id:int, _amount:int, _from:int):
	if(id != ball_owner.get_instance_id()): return;

	if(ball_owner.health <= next_thunder_at_hp):
		increase_after_next = true;
		next_thunder_at_hp -= spawn_thunder_each_hp_lost;
		shoot_speed += 1.0;

func shoot_projectile():
	add_thunder();

func add_thunder():
	if(increase_after_next):
		increase_thunder_needed();

	var p:Projectile = Utils.shoot_projectile(settings.projectile_prefab, ball_owner, ball_owner.weapon_slot.global_rotation, self);
	p.set_speed(projectile_speed);
	p.weapon_owner = self;
	p.scale *= projectile_scale;
	p.global_position = p_spawn.global_position;
	p.global_rotation = p_spawn.global_rotation;
	p.sprite_2d.modulate = Color.GRAY;
	p.sprite_2d.modulate.a = 0.85;
	register_thunder(p);

	hide_rotating_spark(next_thunderstrike_at - next_thunder);

	AudioManager.play_sfx(settings.sfx_shoot, "SFX");

	if(next_thunder == next_thunderstrike_at):
		var t:Dictionary[int,int] = {};
		var s = [];
		for i in thunders_needed - 1:
			s.push_back(next_thunderstrike_at);
			t[next_thunder - (1+i)] = 0;
			t[next_thunder - (2+i)] = 0;
			add_thunderstrike(next_thunder - (2+i), next_thunder - (1+i));

		if(closed && thunders_needed > 2):
			s.push_back(next_thunderstrike_at);
			add_thunderstrike(next_thunder - thunders_needed, next_thunder - 1);

		AudioManager.play_sfx(sfx_thunderstrike);
		reset_rotating_sparks();

		get_tree().create_timer(thunderstrike_duration).timeout.connect(clear_thunderstrike.bind(t.keys(),s));


func add_thunderstrike(i0:int, i1:int):

	thunders[i0].velocity = Vector2.ZERO;
	thunders[i1].velocity = Vector2.ZERO;

	thunders[i0].sprite_2d.modulate = Color.WHITE;
	thunders[i1].sprite_2d.modulate = Color.WHITE;

	var p0:Vector2 = thunders[i0].global_position;
	var p1:Vector2 = thunders[i1].global_position;

	var pos:Vector2 = p0.lerp(p1, 0.5);
	var rot:float = (p1 - p0).angle();
	var dist:float = p0.distance_to(p1);

	var strike:ProjectileBlackThunderStrike = Utils.spawn_projectile(thunderstrike_prefab, ball_owner, pos, rot, self);
	strike.weapon_owner = self;

	strike.thunderstrike_line.set_point_position(0, strike.thunderstrike_line.to_local(p0));
	strike.thunderstrike_line.set_point_position(1, strike.thunderstrike_line.to_local(p1));

	var capsule: CapsuleShape2D = strike.thunderstrike_hitbox.shape;
	capsule.radius = 2.5 / strike.global_scale.x;
	capsule.height = dist / strike.global_scale.x;

	register_thundertrike(strike);

func register_thunder(p:Projectile):
	thunders[next_thunder] = p;
	next_thunder += 1;

func register_thundertrike(p:Projectile):
	thunderstrikes[next_thunderstrike_at] = p;
	next_thunderstrike_at += 1;

func clear_thunderstrike(t, s):

	for i in t:
		thunders[i].destroy(0);
		thunders.erase(i);
		pass

	for i in s:
		thunderstrikes[i].destroy(0);
		thunderstrikes.erase(i);

func increase_thunder_needed():
	next_thunderstrike_at += 1;
	thunders_needed += 1;
	increase_after_next = false;
	add_rotating_spark();

func arrange_rotating_sparks():
	var angle:float = 360.0 / rotating_sparks.size();
	for i in rotating_sparks.size():
		rotating_sparks[i].set_root_dist(rotating_dist);
		rotating_sparks[i].global_rotation_degrees = angle * i;

func hide_rotating_spark(i:int):
	rotating_sparks[i].visible = false;

func reset_rotating_sparks():
	for spark in rotating_sparks:
		spark.visible = true;

func add_rotating_spark():
	var spark:BlackRedSpark = rotating_spark_prefab.instantiate();
	rotating_sparks_parent.add_child(spark);
	rotating_sparks.push_back(spark);
	arrange_rotating_sparks();
