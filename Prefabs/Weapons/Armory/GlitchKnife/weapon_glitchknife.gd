class_name WeaponGlitchKnife extends Weapon

@export var nullslash_dmg:int = 1;
@export var nullslash_scale:float = 1.5;
@export var max_consecutive_nullslashes:int = 2;
@export var free_nullslash_chance:float = 0.5;
@export var consecutive_nullslashes_dmg_limit:int = 12;
@export var glitch_duration_base:float = 0.5;
@export var glitch_duration_min:float = 0.1;
@export var glitch_duration_scale:float = 0.01;
@export var attack_speed_nerf:float = 10.0;
@export var progressive_unstable_attack_speed_nerf_multiplier:float = 1.0;
@export var self_hitstop_delay:float = 0.5;
@export var base_glitch_cd:float = 2.0;
@export var unstable_duration:float = 2.0;
@export var glitch_random_speed_range:Vector2;
@export var unstable_rot_delay:float = 0.08;
@export var fx_spawn_point:Node2D;
@export var fx_nullslash:PackedScene;

@export var sfx_glitch_in:SFX;
@export var sfx_glitch_out:SFX;
@export var sfx_normal_hit:SFX;
@export var sfx_nullslash_hit:SFX;
@export var sfx_nullslash_hit_muga:SFX;

@export var accent_color:Color;
@export var idle_glitch_effect_duration:float = 0.2;

@onready var weapon_hitbox: Hitbox = $Sprite2D/WeaponHitbox

var no_self_hitstop:bool = false;
var glitch_cd:float = 0.0;
var glitch_duration:float = 0.0;
var ui_rot_speed:float = 0.0;
var glitch_cd_remaining:float = 0.0;
var glitch_remaining:float = 0.0;
var unstable_remaining:float = 0.0;
var glitch_rot_speed_bonus:float = 0.0;
var in_glitch:bool = false;
var is_unstable:bool = false;
var unstable_ratio:float = 0.0;
var custom_rot_bonus:float = 0.0;

var consecutive_nullslashes:int = 0;

var unstable_rot_timer:Timer = Timer.new();
var idle_glitch_effect_timer:Timer = Timer.new();
var in_glitch_effect:bool = false;

var idle_glitch_effect_remaining:float = 0.0;

var starting_nullslash_dmg:int = 0;
var starting_glitch_cd:float = 0;
var starting_glitch_duration:float = 0;


func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);

func weapon_is_ready():
	init_vars();

	unstable_rot_timer.wait_time = unstable_rot_delay;
	unstable_rot_timer.timeout.connect(on_unstable_rot_timer);
	add_child(unstable_rot_timer);
	update_details();

func init_scaling_stat():
	scaling_stat_value = nullslash_dmg;
	update_stat_text();

func _physics_process(delta: float) -> void:
	super._physics_process(delta);

	if(in_glitch):
		glitch_remaining -= delta;
		if(glitch_remaining <= 0.0):
			AudioManager.play_sfx(sfx_glitch_out, "SFX");
			toggle_unstable(true);
	else:
		glitch_cd_remaining -= delta;
		if(!in_glitch_effect && glitch_cd_remaining <= idle_glitch_effect_duration):
			AudioManager.play_sfx(sfx_glitch_in, "SFX");
			toggle_idle_glitch(true);
			in_glitch_effect = true;

		if(glitch_cd_remaining <= 0.0):
			execute_glitch();
			glitch_cd_remaining = glitch_cd;
			in_glitch_effect = false;

	if(is_unstable):
		unstable_remaining -= delta;
		unstable_ratio = unstable_remaining / unstable_duration;
		custom_rot_speed_multiplier = 0.75 + glitch_rot_speed_bonus * Scalings.ease_out_expo(unstable_ratio);
		sprite_2d.material.set_shader_parameter("tear_power", 0.1 + ((unstable_ratio / 2.0) * 0.5));

		if(unstable_remaining <= 0.0):
			toggle_unstable(false);
			unstable_rot_timer.wait_time = unstable_rot_delay;
			unstable_rot_timer.stop();

	sprite_2d.rotation_degrees = neutral_sprite_rotation + custom_rot_bonus;
	update_details();

func aled():
	print("Glitch CD %s / %s" % [glitch_cd_remaining, glitch_cd]);
	print("Glitch  %s / %s" % [glitch_remaining, glitch_duration]);
	print("Unstable %s / %s" % [unstable_remaining, unstable_duration]);

func toggle_unstable(state:bool):
	is_unstable = state;
	unstable_remaining = unstable_duration;

	if(state):
		consecutive_nullslashes = 0;
		glitch_remaining = glitch_duration;
		toggle_weapon(true);
		in_glitch = false;
		unstable_ratio = 1.0;
		toggle_unstable_sprite(true);
		on_unstable_rot_timer();
	else:
		custom_rot_speed_multiplier = 1.0;
		toggle_unstable_sprite(false);

func execute_glitch():
	toggle_weapon(false);
	glitch_rot_speed_bonus = randf_range(glitch_random_speed_range.x, glitch_random_speed_range.y);
	custom_rot_speed_multiplier = glitch_rot_speed_bonus;
	rotation_direction *= -1;
	flip_sprite();
	in_glitch = true;

func on_unstable_rot_timer() -> void:
	if(is_unstable):
		custom_rot_bonus = 0.0 if unstable_remaining <= (unstable_duration / 2.0) else randf_range(0.0, 360.0);
		unstable_rot_timer.wait_time = unstable_rot_delay;
		unstable_rot_timer.start();
	else:
		unstable_remaining = unstable_duration;
		custom_rot_bonus = 0.0;

func can_nullslash() -> bool:
	return consecutive_nullslashes < (1 if nullslash_dmg >= consecutive_nullslashes_dmg_limit else max_consecutive_nullslashes);

func toggle_weapon(s:bool):
	self.visible = s;
	self.weapon_hitbox.monitorable = s;
	self.weapon_hitbox.monitoring = s;

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;

	rotation_speed += 0.01;

	if(is_unstable && can_nullslash()):
		nullslash_dmg = (int)(nullslash_dmg + nullslash_scale);
	else:
		glitch_cd = clamp(glitch_cd + stat_scale_value, glitch_duration_min, glitch_cd);
		glitch_duration = clamp(glitch_duration - glitch_duration_scale, glitch_duration_min, glitch_duration_base);

		if(force && randi_range(-1,1) > 0):
			starting_nullslash_dmg += (int)(nullslash_scale);
			starting_glitch_cd = glitch_cd;
			starting_glitch_duration = glitch_duration;
			nullslash_dmg = 1 + starting_nullslash_dmg;

	init_scaling_stat();

func get_custom_damage_value() -> int:
	return nullslash_dmg if (is_unstable && can_nullslash()) else damage;

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, _hitbox_id:int, projectile_hit:Projectile = null) -> void:
	if(ball_owner.is_in_same_team(other)):
		return;

	hitboxes[0].weapon_clash_cd_elapsed = hitboxes[0].weapon_clash_cd * 2.0;
	hitboxes[0].target_cd[other] = hitstop / (0.8 + (rotation_speed / attack_speed_nerf));

	if(!other.silent_on_hit):
		AudioManager.play_sfx(settings.sfx_hit, "SFX");

	var d:int = get_custom_damage_value() if custom_damage else damage;

	var kb_dist:float = knockback + other.linear_velocity.length() if !other.knockback_immune else 0.0;

	var kb:Vector2 = (other.global_position - ball_owner.global_position).normalized() * kb_dist;

	if(projectile_hit):
		kb = (hit_pos - ball_owner.global_position).normalized() * kb_dist;

	other.hit_pos = hit_pos;
	other.affect_health(-d, ball_owner, weapon_slot_id);

	if(!projectile_hit && !no_self_hitstop):
		ball_owner.start_hitstop(0.0, hitstop);
		no_self_hitstop = true;
		get_tree().create_timer(hitstop + self_hitstop_delay).timeout.connect(func(): no_self_hitstop = false);

	other.start_hitstop(0.0, hitstop, kb);
	other.hitflash(hitstop);

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), weapon_slot_id, other.get_instance_id(), projectile_hit != null);
	pass;

func on_weapon_hit_received(id:int, slot_id:int, to:int, _is_projectile:bool):
	if(!is_valid_slot_it(id, slot_id)): return;
	scale_stat();

	if(is_unstable && can_nullslash()):
		var hit_ball:BattleBall = ball_owner.main.get_ball_by_id(to);
		if(hit_ball == null): return;

		if(randf() > free_nullslash_chance): consecutive_nullslashes += 1;
		spawn_nullslash_fx(hit_ball.global_position);
		AudioManager.play_sfx(sfx_nullslash_hit, "SFX");
		AudioManager.play_sfx(sfx_nullslash_hit_muga, "SFX");
		EventBus.set_chromatic_aberration.emit(30, 0.12);
	else:
		AudioManager.play_sfx(sfx_normal_hit, "SFX");

	pass;

func spawn_nullslash_fx(hit_pos:Vector2):
	ball_owner.main.spawn_fx(fx_nullslash, hit_pos, (hit_pos - ball_owner.global_position).normalized().angle());

func toggle_unstable_sprite(v:bool):
	sprite_2d.material.set_shader_parameter("glitch_intensity", 1.0 if v else 0.0);

func toggle_idle_glitch(v:bool):
	if(!v):
		idle_glitch_effect_timer.stop();

	sprite_2d.material.set_shader_parameter("tear_power", 1.0 if v else 0.3);
	sprite_2d.material.set_shader_parameter("tear_speed", 20.0 if v else 5.0);
	sprite_2d.material.set_shader_parameter("glitch_intensity", 1.0 if v else 0.0);

func update_details():
	if(!in_glitch && !is_unstable):
		settings.details = glitch_knife_details();
	else:
		settings.details = unstable_details();

	update_ui_details(Color.WHITE, true);

func glitch_knife_details() -> String:
	return "[color=" + settings.color.to_html() + "]Glitch in[/color] [color=white]" + Utils.format_float(glitch_cd_remaining, 1) + "s" + "[/color] ";

func unstable_details() -> String:
	return "[color=white]+ " + Utils.format_float(nullslash_scale, 1) + " Nullslash[/color][color=" + settings.color.to_html() + "] DMG on hit[/color]";

func reset():

	if(!ball_owner.main.no_reset_mode):
		init_vars();
		super.reset();

func init_vars():
	nullslash_dmg = 1 + starting_nullslash_dmg;
	glitch_cd = base_glitch_cd if starting_glitch_cd == 0.0 else starting_glitch_cd;
	glitch_cd_remaining = base_glitch_cd;
	glitch_remaining = glitch_duration_base;
	glitch_duration = glitch_duration_base if starting_glitch_duration == 0.0 else starting_glitch_duration;
	unstable_remaining = unstable_duration;

func set_battleblock_modifiers(weapon_index:int):
	super.set_battleblock_modifiers(weapon_index);
	#ball_owner.gravity_strength /= 3.5;
	ball_owner.relative_bounce_boost = 0.3;
	hitstop /= 0.2;
	attack_speed = 2.0;
