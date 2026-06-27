class_name WeaponSealed extends Weapon

@export var unsealed_sprite:Texture2D;
@export var clashes_to_unseal:int = 3;
@export var unsealed_hits:int = 3;
@export var unseal_hitstop_duration:float = 1.0;

@export var unsealed_name:String = "Lævateinn";
@export var unsealed_color:Color;

@export var fx_fire_slash:Sprite2D;
@export var fx_chain_break:PackedScene;

@export var sfx_seal:SFX;

@export var sfx_chain_unseal:SFX;

@export var sfx_sealed_clash:SFX;
@export var sfx_sealed_hit:SFX;

@export var sfx_unseal_skill:SFX;
@export var sfx_unsealed_clash:SFX;
@export var sfx_unsealed_hit:SFX;

@export var chains: Array[Sprite2D] = [];
@export var unsealed_aura:Sprite2D;

@export var shake_duration: float = 0.3;
@export var shake_base_intensity: float = 3.0;
@export var shake_intensity_multiplier: float = 1.5;
@export var shake_frequency: float = 20.0;

@export var unsealed_knockback:float = 0.0;
@export var unsealed_rot_speed:float = 0.0;
@export var unsealed_max_speed:float =  0.0;
@export var unsealed_gravity_strength:float = 0.0;

@export var smooth_trail_prefab:PackedScene;
@export var trail_offset:float = 40.0;
@export var trail_length:int = 50;
@export var trail_shader:ShaderMaterial;

var chains_tween: Tween;

var clashes_to_unseal_remaining:int = 0;
var unsealed_hits_remaining:int = 0;
var is_sealed:bool = false;

var sealed_damage:float = 1.0;
var unsealed_damage:float = 1.0;

var sealed_sprite_ui:Texture2D = null;
var sealed_sprite:Texture2D = null;
var sealed_name:String = "";

var sealed_knockback:float = 0.0;
var sealed_rot_speed:float = 0.0;
var sealed_max_speed:float =  0.0;
var sealed_gravity_strength:float = 0.0;

var in_unseal_skill:bool = false;

var unsealed_trail:Trail2DSmooth = null;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);
	EventBus.ball_weapon_clash.connect(on_weapon_clash_received);

func weapon_is_ready():
	unsealed_trail = Utils.spawn_smooth_trail(smooth_trail_prefab, ball_owner, self, trail_offset, trail_length, trail_shader);
	init_vars();

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_KP_5 and not event.pressed:
		on_weapon_clash_received(ball_owner.get_instance_id(),0,Vector2.ZERO,false);

	if event is InputEventKey and event.keycode == KEY_KP_6 and not event.pressed:
		seal();

func init_scaling_stat():
	scaling_stat_value = damage;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	if(lifesteal && !lifesteal_active): return;

	if(is_sealed):
		if(clashes_to_unseal_remaining <= 0):
			unseal();
	else:
		if(unsealed_hits_remaining <= 0):
			seal();
		else:
			damage += 1;

	init_scaling_stat();

func on_weapon_hit_received(id:int, slot_id:int, _to:int, _is_projectile:bool):
	if(!is_valid_slot_it(id, slot_id)): return;

	AudioManager.play_sfx(sfx_sealed_hit if is_sealed else sfx_unsealed_hit, "SFX");

	if(!is_sealed):

		if(!in_unseal_skill):
			unsealed_hits_remaining -= 1;

		scale_stat();
		update_details();

func on_weapon_clash_received(id:int, slot_id:int, _clash_pos:Vector2, _silent:bool):
	if(!is_valid_slot_it(id, slot_id)): return;

	AudioManager.play_sfx(sfx_sealed_clash if is_sealed else sfx_unsealed_clash, "SFX");

	if(is_sealed):
		if(clashes_to_unseal_remaining > 1):
			AudioManager.play_sfx(sfx_chain_unseal, "SFX", 1.0 + randf_range(0.1,0.3) * (clashes_to_unseal - clashes_to_unseal_remaining));
			on_clash_chains(false);

		clashes_to_unseal_remaining -= 1;
		scale_stat();
		update_details();

func unseal():
	apply_stats(true);

	is_sealed = false;
	unsealed_hits_remaining = unsealed_hits;
	damage = unsealed_damage * 1.5;
	sprite_2d.texture = unsealed_sprite;
	unsealed_aura.visible = true;

	start_unseal_skill();

	set_ui_name(unsealed_name, unsealed_sprite);

	update_details();
	init_scaling_stat();
	pass;

func start_unseal_skill():
	var rot_speed:float = 7.0;
	var duration:float = 0.3;

	AudioManager.play_sfx(sfx_unseal_skill, "SFX");

	in_unseal_skill = true;

	hitboxes[0].unclashable = true;
	hitboxes[0].scale = Vector2.ONE * 2.0;

	ball_owner.accumulated_forces = Vector2.ZERO
	ball_owner.start_hitstop(1.0, duration, Vector2.ZERO, true, true)

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_EXPO)

	tween.tween_method(
		func(v: float): custom_rot_speed_multiplier = v,
		1.0,
		rot_speed,
		duration * 0.3
	)

	tween.parallel().tween_property(fx_fire_slash, "material:shader_parameter/progress", 0.1, 0.2);
	tween.tween_interval(0.1)
	tween.tween_property(fx_fire_slash, "material:shader_parameter/progress", 0.2, 0.3);
	tween.tween_callback(end_unseal_skill);

func end_unseal_skill():
	hitboxes[0].unclashable = false;
	hitboxes[0].scale = Vector2.ONE;
	custom_rot_speed_multiplier = 1.0;
	fx_fire_slash.material.set_shader_parameter("progress", 0.0);

	unsealed_trail.clear_points();
	unsealed_trail.visible = true;

	in_unseal_skill = false;

func seal():
	apply_stats(false);
	reset_chains();
	AudioManager.play_sfx(sfx_seal, "SFX");
	seal_sfx_tween();
	on_clash_chains(true);
	set_ui_name(sealed_name, sealed_sprite_ui);

	is_sealed = true;
	clashes_to_unseal_remaining = clashes_to_unseal;
	unsealed_damage = damage;
	sealed_damage += 1;
	damage = sealed_damage;
	sprite_2d.texture = sealed_sprite;
	unsealed_aura.visible = false;
	unsealed_trail.visible = false;

	update_details();
	init_scaling_stat();
	pass;

func seal_sfx_tween():
	var t:Tween = create_tween();

	for i in 3:
		t.tween_callback(func(): AudioManager.play_sfx(sfx_chain_unseal, "SFX", 1.0 + (randf_range(0.4,0.7) * i)));
		t.tween_interval(0.1);

func on_clash_chains(visual_only:bool):
	if chains_tween:
		chains_tween.kill()
		for s in chains:
			s.position = Vector2.ZERO

	var index: int = clashes_to_unseal - clashes_to_unseal_remaining
	var intensity = shake_base_intensity * pow(shake_intensity_multiplier, index / 2.0)
	chains_tween = create_tween()
	chains_tween.set_parallel(true)

	for sprite in chains:
		Utils._shake_sprite(chains_tween, sprite, intensity, shake_duration, shake_frequency)

	if(!visual_only):
		chains_tween.chain().tween_callback(func():
			chains[index].visible = false
			chains[index].position = Vector2.ZERO
			ball_owner.main.spawn_fx(fx_chain_break, chains[index].global_position, chains[index].global_rotation);
		)

func set_ui_name(n:String, spr:Texture2D):
	settings.name = n;
	ui_sprite.texture = spr;
	update_ui_name(settings.color);

func save_sealed_stats():
	sealed_gravity_strength = ball_owner.gravity_strength;
	sealed_knockback = knockback;
	sealed_max_speed = ball_owner.max_speed;
	sealed_rot_speed = rotation_speed;

func apply_stats(unsealed:bool):
	ball_owner.gravity_strength = unsealed_gravity_strength if unsealed else sealed_gravity_strength;
	knockback = unsealed_knockback if unsealed else sealed_knockback;
	ball_owner.max_speed = unsealed_max_speed if unsealed else sealed_max_speed;
	rotation_speed = unsealed_rot_speed if unsealed else sealed_rot_speed;

func reset_chains():
	if chains_tween:
		chains_tween.kill()
	for sprite in chains:
		sprite.visible = true
		sprite.position = Vector2.ZERO

func update_details():
	settings.details = sealed_details() if is_sealed else unsealed_details();
	update_ui_details(Color.WHITE, true);

func sealed_details() -> String:
	var p:String = "parries" if clashes_to_unseal_remaining > 1 else "parry";
	var v:String = "[color=%s]%s[/color]" % [unsealed_color.to_html(), clashes_to_unseal_remaining];
	return "[color=%s]Unseal in %s %s[/color]" % [settings.color.to_html(), v, p];

func unsealed_details() -> String:
	var h:String = "hits" if unsealed_hits_remaining > 1 else "hit";
	var v:String = "[color=%s]%s[/color]" % [settings.color.to_html(), unsealed_hits_remaining];
	return "[color=%s]Dmg x1.5 - Seal in %s %s[/color]" % [unsealed_color.to_html(), v, h];

func reset():
	if(!ball_owner.main.no_reset_mode):
		init_vars();
		super.reset();

func init_vars():
	sealed_sprite = sprite_2d.texture;
	sealed_sprite_ui = settings.spr;
	clashes_to_unseal_remaining = clashes_to_unseal;
	unsealed_hits_remaining = unsealed_hits;
	sealed_damage = 0.0;
	unsealed_damage = 1.0;
	sealed_name = settings.name;

	save_sealed_stats();

	seal();
