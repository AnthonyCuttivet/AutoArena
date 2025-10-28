class_name WeaponBones extends Weapon

@export var bounces:float = 0;
@export var bad_time_bounces:int;
@export var bad_time_duration:float = 5.0;
@export var laser_hits:int = 10;
@export var laser_duration:float = 0.5;
@export var laser_hitstop:float = 0.2;
@export var laser_spawn_dist:float = 1000.0;
@export var laser_move_duration:float = 0.5;
@export var laser_prefab:PackedScene;
@export var bones_sprites:Array[Texture2D];
@export var phantom_bone_opacity:float = 0.5;

@export var eye_prefab:PackedScene;
@export var eye_scale:float = 3.0;

@export var accent_color:Color;
@export var quotes:Array[String];

@export var sfx_battle_start:SFX;
@export var sfx_bad_time:SFX;
@export var sfx_laser:SFX;
@export var sfx_megalovania:SFX;
@export var sfx_sans:SFX;
@export var sfx_death:SFX;

@onready var collider: CollisionShape2D = $Sprite2D/WeaponHitbox/CollisionShape2D

var remaining_bad_time_bounces:int = 0;
var remaining_laser_hits:int = 0;
var eye:BonesEye = null;
var bad_time_mode:bool = false;
var active_laser:ProjectileBonesLaser = null;
var laser_width_modifier:float = 1.0;
var can_shoot:bool = true;
var laser_final_pos:Vector2 = Vector2.ZERO;
var laser_final_rot:float = 0.0;

func _init() -> void:
	EventBus.ball_started.connect(on_ball_started);
	EventBus.ball_weapon_hit.connect(on_listened_event_received);
	EventBus.ball_damaged.connect(on_ball_damaged_received);
	EventBus.projectile_bounced.connect(on_projectile_bounced);

func weapon_is_ready():
	spawn_eye();
	reset_bad_time_bounces();
	reset_laser_hits();
	update_details();

func on_ball_started(id:int):
	if(id != ball_owner.get_instance_id()): return false;
	AudioManager.play_sfx(sfx_battle_start);

func init_scaling_stat():
	scaling_stat_value = bounces;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	bounces += stat_scale_value;
	init_scaling_stat();

func on_projectile_bounced(_id:int, weapon_id:int):
	if(weapon_id != get_instance_id()): return;

	if(!bad_time_mode):
		remaining_bad_time_bounces -= 1;
		if(remaining_bad_time_bounces <= 0):
			reset_bad_time_bounces();
			start_bad_time();

		update_details();

func on_listened_event_received(id:int, slot_id:int, _to:int, _is_projectile:bool):
	if(!is_valid_slot_it(id, slot_id)): return;

	if(bad_time_mode && active_laser == null):
		remaining_laser_hits -= 1;
		update_details();
		if(remaining_laser_hits <= 0):
			reset_laser_hits();
			fire_laser();
	else:
		scale_stat();
	pass;

func on_ball_damaged_received(id:int, _amount:int, _from:int, _slot_id:int):
	if(id != ball_owner.get_instance_id()): return;
	AudioManager.play_sfx(sfx_sans);

	if(ball_owner.health <= 0):
		ball_owner.main.play_sfx(sfx_death, "SFX", 1.0,0.0,0.0,true);

func shoot_projectile() -> Projectile:
	if(ball_owner.debug_no_shoot): return;
	if(settings.projectile_prefab == null):return;
	if(!can_shoot): return;

	AudioManager.play_sfx(settings.sfx_shoot if !custom_sfx else custom_sfx_sound, "SFX");

	var p:Projectile = settings.projectile_prefab.instantiate();

	if(projectile_spawn != null):
		p.global_position = projectile_spawn.global_position;
	else:
		p.global_position = sprite_2d.global_position;

	p.rotation = weapon_slot.global_rotation;
	p.scale = weapon_slot.scale * ball_owner.root.scale * projectile_scale;

	if(!settings.no_projectile_scale_change):
		p.hitbox.scale *= 1.0 + cheat_hitbox_scale_bonus;

	p.weapon_owner = self;
	p.init(ball_owner, self, projectile_speed, (-1 if !bad_time_mode else 999), int(bounces));
	p.sprite_2d.texture = bones_sprites[0 if !bad_time_mode else 1];
	p.sprite_2d.self_modulate.a = 1.0 if !bad_time_mode else phantom_bone_opacity;

	if(settings.bg_projectile):
		ball_owner.main.projectiles_bg_parent.add_child(p);
	else:
		get_tree().root.add_child(p);

	owned_projectiles.push_back(p);

	if(lifesteal_active):
		p.sprite_2d.self_modulate = Color.DARK_RED;

	return p;

func reset_bad_time_bounces():
	remaining_bad_time_bounces = bad_time_bounces;

func reset_laser_hits():
	remaining_laser_hits = laser_hits;

func spawn_eye():
	eye = eye_prefab.instantiate();
	ball_owner.additional_element.add_child(eye);
	eye.scale *= eye_scale;
	eye.position = Vector2(160,-120);
	eye.activate(false);

func start_bad_time():
	if(bad_time_mode): return;

	bad_time_mode = true;

	eye.activate(true);
	AudioManager.play_sfx(sfx_bad_time);
	get_tree().create_timer(0.1).timeout.connect(func():AudioManager.play_sfx(sfx_megalovania, "SFX"));
	sprite_2d.texture = bones_sprites[1];

	update_details();

	get_tree().create_timer(bad_time_duration).timeout.connect(stop_bad_time);

func stop_bad_time():
	sprite_2d.texture = bones_sprites[0];
	bad_time_mode = false;
	eye.activate(false);

	update_details();

	for p in owned_projectiles:
		if(p != null):
			p.pierce_count = 0;
			p.sprite_2d.texture = bones_sprites[0];
			p.sprite_2d.self_modulate.a = 1.0;

func fire_laser():
	AudioManager.play_sfx(sfx_laser, "SFX");

	set_can_shoot(false);
	ball_owner.start_hitstop(0.0, laser_duration + 0.5, Vector2.ZERO, true, true);

	var laser:ProjectileBonesLaser = Utils.spawn_projectile(laser_prefab, ball_owner, self, get_laser_spawn_pos(), deg_to_rad(randf_range(0.0,360.0)), ball_owner.main.projectiles_bg_parent);
	active_laser = laser;
	laser.weapon_owner = self;
	laser.custom_damage = 1;
	laser.custom_hitstop = laser_hitstop;

func get_laser_spawn_pos() -> Vector2:
	var side:int = randi_range(0, 1) * 2 - 1;
	var pos_id:int = randi_range(0,4);
	var center_x:float = ball_owner.main.arena_center.global_position.x;
	var pos_x:float = 0.0;

	match pos_id:
		0: pos_x = center_x + 450.0; laser_final_rot = 225.0;
		1: pos_x = center_x + 225.0; laser_final_rot = 270.0;
		2: pos_x = center_x; laser_final_rot = 270.0;
		3: pos_x = center_x - 225.0; laser_final_rot = 270.0;
		4: pos_x = center_x - 450.0; laser_final_rot = 315.0;

	laser_final_rot *= side;

	laser_final_pos = Vector2(pos_x, ball_owner.main.arena_center.global_position.y + (side * 450.0));
	return Vector2(pos_x, ball_owner.main.arena_center.global_position.y + (side * laser_spawn_dist));

func set_can_shoot(s:bool):
	if(s && active_laser != null): return;
	can_shoot = s;
	sprite_2d.self_modulate.a = 0.0 if !s else 1.0;

	collider.set_deferred("disabled", !s);

	update_details(!s);

func update_details(laser_mode:bool = false):
	if(laser_mode):
		settings.details = laser_details();
	else:
		settings.details = bones_details() if !bad_time_mode else bad_time_details();

	update_ui_details(Color.WHITE, true);

func bones_details() -> String:
	var b:String = "bounces" if remaining_bad_time_bounces > 1 else "bounce";
	return "[wave amp=25.0 freq=8][color=" + accent_color.to_html() + "]Bad Time[/color][/wave] in [color=red]" + str(remaining_bad_time_bounces) + " " + b + "[/color] ";

func bad_time_details() -> String:
	var h:String = "hits" if remaining_laser_hits > 1 else "hit";
	return "[wave amp=50.0 freq=16][color=" + accent_color.to_html() + "]Laser[/color][/wave] in [color=red]" + str(remaining_laser_hits) + " " + h + "[/color] ";

func laser_details() -> String:
	return "[wave amp=25.0 freq=8]" + quotes[randi() % quotes.size() - 1] + "[/wave]";
