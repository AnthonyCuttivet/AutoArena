class_name Weapon extends Node2D

@export var sprite_2d: Sprite2D;
@export var hitboxes: Array[Hitbox];
@export var custom_damage:bool = false;
@export var custom_sfx:bool = false;

var settings:WeaponSettings;

var melee:bool = false;
var ranged:bool = false;

var rotation_direction:int = 0;
var rotation_speed:float = 0.0;
var damage:int = 0;
var knockback:float = 0.0;
var attack_speed:float = 0.0;
var shoot_speed:float = 0.0;
var size:float = 0.0;
var projectiles:int = 0;
var projectile_speed:float = 0.0;
var projectile_scale:float = 0.75;
var shoot_duration:float = 1.0;
var hitstop:float = 0.0;
var rot_speed_bounce_boost:bool = false;
var projectile_self_hitstop:bool = false;
var lifesteal:bool = false;
var lifesteal_tick:int = 0;
var lifesteal_ticked:int = 0;
var lifesteal_active:bool = false;

var scaling_stat_value:float = 0.0;
var stat_scale_value:float = 0.0;

var ball_owner:BattleBall;

var attack_speed_elapsed:float = 0.0;
var shoot_speed_elapsed:float = 0.0;
var shoots_remaining:int = 0;

var no_shoot:bool = false;
var owned_projectiles:Array[Projectile] = [];

var no_stat_scale:bool = false;
var scale_stat_multiplier:int = 1;

var battleblock_mode:bool = false;

var cheat_hitbox_scale_bonus:float = 0.0;

func init(s:WeaponSettings, o:BattleBall) -> void:

	ball_owner = o;

	if(s == null):
		sprite_2d.texture = null;
		for hitbox in hitboxes:
			if(hitbox != null):
				hitbox.monitorable = false;
				hitbox.monitoring = false;
		return;

	settings = s;

	melee = settings.melee;
	ranged = settings.ranged;

	rotation_direction = settings.base_rotation_direction;
	rotation_speed = settings.base_rotation_speed;
	damage = settings.base_damage;
	knockback = settings.base_knockback;
	attack_speed = settings.base_attack_speed;
	attack_speed_elapsed = (1.0 / attack_speed);
	shoot_speed = settings.base_shoot_speed;
	shoot_speed_elapsed = (1.0 / shoot_speed);
	size = settings.base_attack_speed;
	projectiles = settings.base_projectiles;
	projectile_speed = settings.base_projectile_speed;
	projectile_scale = settings.base_projectile_scale;
	shoot_duration = settings.base_shoot_duration;
	hitstop = settings.base_hitstop;
	shoots_remaining = projectiles;
	rot_speed_bounce_boost = settings.base_rot_speed_bounce_boost;
	projectile_self_hitstop = settings.projectile_self_hitstop;

	lifesteal = settings.lifesteal;
	lifesteal_tick = settings.lifesteal_tick;
	lifesteal_ticked = lifesteal_tick;

	stat_scale_value = settings.stat_scale_value;
	scale_stat_multiplier = settings.scale_stat_multiplier;

	if(rotation_direction == -1 && settings.flip):
		flip_sprite();

	init_scaling_stat();

	for hitbox in hitboxes:
		if(hitbox != null):
			hitbox.ball_owner = o;
			hitbox.init();

func _physics_process(delta: float) -> void:

	if(ball_owner.dead || ball_owner.stop): return;

	if(!ball_owner.end_game && ranged && shoots_remaining > 0 && !ball_owner.freeze):
		shoot_speed_elapsed += delta * ball_owner.time_scale;
		if(shoot_speed_elapsed >= (1.0 / shoot_speed)):
			shoots_remaining -= 1;
			shoot_projectile();
			if(shoots_remaining > 0):
				shoot_speed_elapsed = (1.0 / shoot_speed) - (shoot_duration / projectiles);
			else:
				shoot_speed_elapsed = 0.0;
				reset_shoots();

func reset_shoots():
	shoots_remaining = projectiles;

func add_remaining_shoot():
	shoots_remaining += 1;

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, _hitbox_id:int, projectile_hit:bool = false) -> void:
	if(other.is_invincible()):
		print(other.name + " is INVINCIBLE");
		return;

	if(ball_owner.is_in_same_team(other)):
		return;

	if(!custom_sfx && !other.silent_on_hit):
		AudioManager.play_sfx(settings.sfx_hit, "SFX");

	var d:int = get_custom_damage_value() if custom_damage else damage;

	var kb_dist:float = knockback + other.linear_velocity.length() if !other.knockback_immune else 0.0;
	var kb:Vector2 = (other.global_position - ball_owner.global_position).normalized() * kb_dist;
	var h:float = hitstop;

	if(lifesteal && lifesteal_active):
		h *= 1.25;

	if(projectile_hit):
		kb = (hit_pos - ball_owner.global_position).normalized() * kb_dist;

	other.affect_health(-d, ball_owner);

	if(!projectile_hit):
		ball_owner.start_hitstop(0.0, h);
	else:
		if(projectile_self_hitstop):
			ball_owner.start_hitstop(0.0, h);


	other.start_hitstop(0.0, h, kb);
	other.hitflash(h);
	other.hit_pos = hit_pos;

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), other.get_instance_id(), projectile_hit);
	pass;

func on_weapon_clash(other:Node2D, clash_pos:Vector2, projectile_hit:bool = false, silent:bool = false):
	if(other == null): return;
	# if(ball_owner.is_in_same_team(other)):
	# 	return;

	if(!silent):
		AudioManager.play_sfx(settings.sfx_clash, "SFX");

	var kb:Vector2 = Vector2.ZERO;

	if(!projectile_hit):
		kb = (ball_owner.global_position - other.global_position).normalized() * ball_owner.linear_velocity.length() * 1.5;
		reverse_rotation();

	ball_owner.start_hitstop_clash(0.0, 0.15, kb, other);

	EventBus.ball_weapon_clash.emit(ball_owner.get_instance_id(), clash_pos, silent);
	pass;

func reverse_rotation():
	if(settings.no_rotation_change):
		return;

	rotation_direction *= -1;

	if(settings.flip):
		flip_sprite();

func flip_sprite():
	sprite_2d.rotation_degrees += (90.0 * sprite_2d.scale.x);
	sprite_2d.scale.x *= -1.0;

func init_scaling_stat():
	pass;

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	if(lifesteal && !lifesteal_active): return;
	pass;

func shoot_projectile():
	if(ball_owner.no_shoot): return;
	if(settings.projectile_prefab == null):return;

	AudioManager.play_sfx(settings.sfx_shoot, "SFX");

	var p:Projectile = settings.projectile_prefab.instantiate();
	p.global_position = sprite_2d.global_position;
	p.rotation = ball_owner.weapon_slot.global_rotation;
	p.scale = ball_owner.weapon_slot.scale * ball_owner.root.scale * projectile_scale;
	p.hitbox.scale *= 1.0 + cheat_hitbox_scale_bonus;
	p.weapon_owner = self;
	p.init(ball_owner, projectile_speed, 0, 0);

	if(settings.bg_projectile):
		ball_owner.main.projectiles_bg_parent.add_child(p);
	else:
		get_tree().root.add_child(p);

	owned_projectiles.push_back(p);

	if(lifesteal_active):
		p.sprite_2d.self_modulate = Color.DARK_RED;

func on_listened_event_received(_id:int, _to:int, _is_projectile:bool):
	pass;

func get_custom_damage_value() -> int:
	return 0;

func get_custom_stat_format() -> String:
	return "";

func reset():
	for p in owned_projectiles:
		if(p != null):
			p.queue_free();

	owned_projectiles.clear();
	init_scaling_stat();
	pass;

func apply_lifesteal(v:int, target:int):
	ball_owner.affect_health(v, ball_owner);
	EventBus.ball_lifesteal.emit(target, ball_owner.get_instance_id());

func update_lifesteal_status():
	if(lifesteal_active):
		lifesteal_ticked = lifesteal_tick;
		toggle_lifesteal_state(false);
	else:
		lifesteal_ticked -= 1;
		if(lifesteal_ticked == 0):
			toggle_lifesteal_state(true);

func toggle_lifesteal_state(s:bool):
	lifesteal_active = s;
	sprite_2d.self_modulate = Color.WHITE if !s else Color.DARK_RED;
	ball_owner.update_ui_stat(ball_owner.color if !s else Color.DARK_RED);
	ball_owner.update_stat_text();

func set_battleblock_modifiers():
	ball_owner.can_respawn = true;
	ball_owner.root.scale *= 0.45;
	ball_owner.nerf_max_speed(0.3);
	ball_owner.gravity_strength *= 3.5;
	ball_owner.weapon.hitstop *= 0.2;
	ball_owner.drag_force *= 2.0;
	ball_owner.weapon.no_stat_scale = true;
	ball_owner.health = 1;
	ball_owner.weapon.damage = 1 * ball_owner.weapon_settings.base_damage_multiplier;
	ball_owner.min_horizontal = 0;
	ball_owner.clash_invincibility *= 0.1;
	ball_owner.bounce_boost = 0.0;
	ball_owner.relative_bounce_boost = 0.0;
	ball_owner.weapon.battleblock_mode = true;

	for h in ball_owner.weapon.hitboxes:
		h.weapon_clash_cd = 0.0;

func on_bb_death():
	pass;
