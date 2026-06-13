class_name Weapon extends Node2D

@export var sprite_2d: Sprite2D;
@export var hitboxes: Array[Hitbox];
@export var custom_damage:bool = false;
@export var custom_sfx:bool = false;
@export var projectile_spawn:Node2D;

var settings:WeaponSettings;

var melee:bool = false;
var ranged:bool = false;
var weapon_slot:Node2D = null;
var weapon_slot_id:int = 0;
var rotation_direction:int = 0;
var rotation_speed:float = 0.0;
var rot_speed_multiplier:float = 1.0;
var custom_rot_speed_multiplier:float = 1.0;
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
var hitstop_slow:float = 0.0;
var projectile_self_hitstop:bool = false;
var lifesteal:bool = false;
var lifesteal_tick:int = 0;
var lifesteal_ticked:int = 0;
var lifesteal_active:bool = false;

var scaling_stat_value:float = 0.0;
var stat_scale_value:float = 0.0;

var scaling_index:int = 0;
var scaling_damage:int = 1;

var ball_owner:BattleBall;

var attack_speed_elapsed:float = 0.0;
var shoot_speed_elapsed:float = 0.0;
var shoots_remaining:int = 0;
var align_weapon_to_velocity:bool = false;

var no_shoot:bool = false;
var owned_projectiles:Array[Projectile] = [];

var no_stat_scale:bool = false;
var dual_scale:bool = true;
var scale_stat_multiplier:int = 1;

var battleblock_mode:bool = false;

var cheat_hitbox_scale_bonus:float = 0.0;

var clash_tween:Tween = null;
var custom_sfx_sound:SFX = null;

var name_text:DynamicText = null;
var ui_sprite:TextureRect = null;
var details_text:DynamicText = null;
var stat_text:DynamicText = null;
var bb_mult_text:DynamicText = null;

var neutral_sprite_rotation:float = 45.0;

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
	hitstop_slow = settings.base_hitstop_slow;
	shoots_remaining = projectiles;
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

func weapon_is_ready():
	pass;

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

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, _hitbox_id:int, projectile_hit:Projectile = null) -> void:
	if(other.is_invincible()):
		# print(other.name + " is INVINCIBLE");
		return;

	if(ball_owner.is_in_same_team(other)):
		return;

	if(projectile_hit && projectile_hit.custom_hit_sfx != null):
		AudioManager.play_sfx(projectile_hit.custom_hit_sfx, "SFX");
	elif(!custom_sfx && !other.silent_on_hit):
		AudioManager.play_sfx(settings.sfx_hit, "SFX");

	var d:int = get_custom_damage_value() if custom_damage else damage;

	var kb_dist:float = knockback + other.linear_velocity.length() if !other.knockback_immune else 0.0;
	var kb:Vector2 = (other.global_position - ball_owner.global_position).normalized() * kb_dist;
	var h:float = hitstop;

	if(projectile_hit && projectile_hit.custom_hitstop != -1.0):
		h = projectile_hit.custom_hitstop;

	if(lifesteal && lifesteal_active):
		h *= 1.25;

	if(projectile_hit):
		kb = (hit_pos - ball_owner.global_position).normalized() * kb_dist;
		if(projectile_hit.custom_damage != -1):
			d = projectile_hit.custom_damage;

	other.hit_pos = hit_pos;

	other.affect_health(-d, ball_owner, weapon_slot_id);

	if(!projectile_hit):
		ball_owner.start_hitstop(hitstop_slow, h);
	else:
		if(projectile_self_hitstop):
			ball_owner.start_hitstop(hitstop_slow, h);

	other.hitflash(h);
	other.start_hitstop(hitstop_slow, h, kb);

	# print(Utils.pf() + " Emit BALL_WEAPON_HIT - " + str(ball_owner.get_instance_id()) + " // " + str(weapon_slot_id));

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), weapon_slot_id, other.get_instance_id(), projectile_hit != null);
	pass;

func on_weapon_clash(other:Node2D, clash_pos:Vector2, projectile_hit:bool = false, silent:bool = false, force:bool = false):
	if(other == null): return;

	if(!force && ball_owner.is_in_same_team(other)):
		return;

	if(!silent):
		AudioManager.play_sfx(settings.sfx_clash, "SFX");

	var kb:Vector2 = Vector2.ZERO;

	if(!projectile_hit):
		kb = (ball_owner.global_position - other.global_position).normalized() * ball_owner.linear_velocity.length() * 1.5;
		reverse_rotation();


	ball_owner.start_hitstop_clash(0.0, 0.15, kb, other);

	EventBus.ball_weapon_clash.emit(ball_owner.get_instance_id(), weapon_slot_id, clash_pos, silent);
	pass;

func clash_gamefeel() -> void:
	if clash_tween and clash_tween.is_running():
		clash_tween.kill();
		rot_speed_multiplier = 1.0;

	# Boost instantly
	rot_speed_multiplier = 5.0;

	# Tween back smoothly
	clash_tween = create_tween();
	clash_tween.tween_property(self, "scale", Vector2.ONE * 1.2, 0.07).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT);
	clash_tween.tween_property(self, "rot_speed_multiplier", 1.0, 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_delay(0.1);
	clash_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);

func reverse_rotation():
	if(settings.no_rotation_change):
		return;

	if(!ball_owner.no_clash_gamefeel):
		clash_gamefeel();

	rotation_direction *= -1;

	if(settings.flip):
		flip_sprite();

func flip_sprite():
	sprite_2d.rotation_degrees = 45.0 if sign(sprite_2d.scale.x) > 0 else 135.0;
	sprite_2d.rotation_degrees += (90.0 * sprite_2d.scale.x);
	neutral_sprite_rotation = sprite_2d.rotation_degrees;
	sprite_2d.scale.x *= -1.0;

func init_scaling_stat():
	pass;

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	if(lifesteal && !lifesteal_active): return;
	pass;

func shoot_projectile() -> Projectile:
	if(ball_owner.debug_no_shoot): return;
	if(settings.projectile_prefab == null):return;

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
	p.init(ball_owner, self, projectile_speed);

	if(settings.bg_projectile):
		ball_owner.main.projectiles_bg_parent.add_child(p);
	else:
		get_tree().root.add_child(p);

	owned_projectiles.push_back(p);

	if(lifesteal_active):
		p.sprite_2d.self_modulate = Color.DARK_RED;

	return p;

func on_listened_event_received(_id:int, _slot_id:int, _to:int, _is_projectile:bool):
	pass;

func get_custom_damage_value() -> int:
	return 0;

func get_custom_stat_format() -> String:
	return "";

func clear_owner_projectile():
	for p in owned_projectiles:
		if(p != null):
			p.queue_free();

	owned_projectiles.clear();

func reset():
	clear_owner_projectile();
	init_scaling_stat();
	pass;

func apply_lifesteal(v:int, target:int):
	ball_owner.affect_health(v, ball_owner, weapon_slot_id);
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
	update_ui_stat(settings.color if !s else Color.DARK_RED);
	update_stat_text();

func set_battleblock_modifiers(weapon_index:int):
	if(weapon_index > ball_owner.weapons.size() - 1): return;

	var w:Weapon = ball_owner.weapons[weapon_index];

	ball_owner.can_respawn = true;
	ball_owner.root.scale *= 0.3;
	ball_owner.nerf_max_speed(0.3);
	ball_owner.gravity_strength = 1000.0 + (w.settings.gravity_strength * 0.25);
	ball_owner.drag_force *= 2.0;
	ball_owner.health = 1;
	ball_owner.min_horizontal = 0;
	ball_owner.clash_invincibility *= 0.1;
	ball_owner.bounce_boost = 0.0;
	ball_owner.relative_bounce_boost = 0.2;

	w.hitstop *= 0.2;
	w.no_stat_scale = true;
	w.damage = 1 * w.settings.base_damage_multiplier;
	w.battleblock_mode = true;

	for h in w.hitboxes:
		h.weapon_clash_cd = 0.0;

func on_bb_death():
	pass;

func is_valid_slot_it(id:int, slot_id:int) -> bool:
	if(id != ball_owner.get_instance_id()): return false;

	if(dual_scale):
		return true;
	else:
		return slot_id == weapon_slot_id;


# ---------- UI -------------

func update_stat_text(no_bump:bool = false):
	if(stat_text == null): return;

	var s:String = get_custom_stat_format();

	if(s == ""):
		if(settings.scaling_stat_float):
			s = Utils.format_float(scaling_stat_value, 1);
		else:
			s = str(int(scaling_stat_value));

	stat_text.format([settings.stat_scale_name, s]);
	if(!no_bump):
		stat_text.bump(1.08, 0.08);

func update_scaling_stat_text():
	if(stat_text == null): return;

	stat_text.format([settings.stat_scale_name, Utils.format_number_with_dots(scaling_damage)]);
	stat_text.bump(1.08, 0.08);

func update_bb_mult_text():
	if(bb_mult_text == null): return;

	bb_mult_text.format(["Multiplier", "x " + str(scale_stat_multiplier)]);
	bb_mult_text.bump(1.08, 0.08);

func update_ui_name(c:Color, t:String = ""):
	if(name_text == null): return;
	if(t == ""):
		name_text.format([settings.name]);
	else:
		name_text.text = t;

	name_text.self_modulate = c;

func update_ui_sprite(c:Color = Color.WHITE):
	ui_sprite.texture = sprite_2d.texture;
	ui_sprite.self_modulate = c;

func update_ui_details(c:Color, raw:bool = false):
	if(raw):
		details_text.text = settings.details;
	else:
		details_text.format([settings.details]);

	details_text.modulate = c;

func update_ui_stat(c:Color):
	stat_text.self_modulate = c;
