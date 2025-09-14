class_name WeaponScissors extends Weapon

@export var invincibility:float = 0.1;
@export var speed_boost:float = 5.0;
@export var dash_duration:float = 0.5;
@export var dash_self_hitstop:float = 0.25;
@export var additional_trail_length:int = 20;
@export var dash_hit_hitstop:float = 0.6;
@export var dash_damage:int = 4;
@export var dash_knockback:float = 2500.0;
@export var hit_attack_texture:Texture;
@export var sfx_dash:SFX;
@export var sfx_dash_hit:SFX;
@export var sfx_dash_snip:SFX;

@onready var opened: Sprite2D = $Opened

@onready var closed_hitbox: Hitbox = $Closed/ClosedHitbox
@onready var scissors_opened_hitbox: Hitbox = $Opened/ScissorsOpenedHitbox

var base_dash_damage:int = 0;
var dashing:bool = false;
var weapon_opened:bool = false;
var dash_hit_registered:bool = false;
var dash_timer:SceneTreeTimer = null;

var pre_dash_max_speed:float = 0.0;
var pre_dash_drag_force:float = 0.0;

var hit_attack_base_texture:Texture;

var block_closing:bool = false;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_listened_event_received);
	base_dash_damage = dash_damage;

# func _process(delta: float) -> void:
# 	if(dashing):
# 		DebugDraw2D.arrow_vector(ball_owner.global_position, ball_owner.linear_velocity.normalized() * 50, Color.RED, 2.0, dash_duration + dash_self_hitstop);

func init_scaling_stat():
	scaling_stat_value = dash_damage;
	ball_owner.update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	dash_damage += stat_scale_value;
	init_scaling_stat();

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, _hitbox_id:int, projectile_hit:bool = false) -> void:
	if(ball_owner.is_in_same_team(other)):
		return;

	if(ball_owner.hitstop_remaining > 0.0):
		return;

	var k:float = knockback if !weapon_opened else dash_knockback;
	var d:int = dash_damage / 2 if weapon_opened else 1;
	var kb_dist:float = k + other.linear_velocity.length() if !other.is_boss else 0.0;
	var kb:Vector2 = (other.global_position - ball_owner.global_position).normalized() * kb_dist;
	var h:float = dash_hit_hitstop if weapon_opened else hitstop;

	if(projectile_hit):
		kb = (hit_pos - ball_owner.global_position).normalized() * kb_dist;

	if(weapon_opened):
		if(dash_hit_registered): return;
		block_closing = true;
		ball_owner.lock_position(true);
		other.lock_position(true);
		# DebugDraw2D.circle_filled(ball_owner.global_position, 10, 16, Color.PURPLE, dash_hit_hitstop);
		dash_hit();
		get_tree().create_timer(dash_hit_hitstop * 0.6).timeout.connect(dash_hit_snip_2.bind(other, kb));
		get_tree().create_timer(dash_hit_hitstop * 0.9).timeout.connect(dash_hit_stop);

	if(!other.silent_on_hit):
		AudioManager.play_sfx(settings.sfx_hit if !weapon_opened else sfx_dash_hit, "SFX");

	other.affect_health(-d, ball_owner);

	# if(weapon_opened): print(Utils.pf() + " Open Hit");
	# else: print(Utils.pf() + " Closed hit");

	if(!projectile_hit):
		ball_owner.start_hitstop(0.0, h);

	other.start_hitstop(0.0, h, kb);
	other.hitflash(hitstop);
	other.hit_pos = hit_pos;

	#if(weapon_opened):
		#scale_stat();

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), other.get_instance_id(), projectile_hit);
	pass;

func on_listened_event_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	pass;

func on_ball_bounce_other_ball(id:int, other:int):
	if(dash_hit_registered): return;
	if(!weapon_opened): return;
	if(id != ball_owner.get_instance_id()): return;
	var other_ball:BattleBall = ball_owner.main.get_ball_by_id(other);
	if(ball_owner.is_in_same_team(other_ball)): return;

	on_weapon_hit(other_ball, ball_owner.global_position, hitboxes[0].get_instance_id());

	pass;

func start_dash(dir:Vector2):
	if(hit_attack_base_texture == null):
		hit_attack_base_texture = opened.texture;

	if(dashing):
		reset_dash(dir);
		return;

	# print(Utils.pf() + " Start Dash");

	#ball_owner.add_invincibility(invincibility + dash_self_hitstop);
	dashing = true;

	AudioManager.play_sfx(sfx_dash, "SFX");

	pre_dash_max_speed = ball_owner.max_speed;
	pre_dash_drag_force = ball_owner.drag_force;

	ball_owner.toggle_ball_ball_collision(false);
	ball_owner.ghost = true;
	ball_owner.weapon_slot.rotation = dir.angle() - deg_to_rad(90.0);
	ball_owner.block_weapon_rot = true;
	ball_owner.linear_velocity = dir * ball_owner.linear_velocity.length();
	ball_owner.align_weapon_to_velocity = true;
	ball_owner.max_speed *= speed_boost;
	ball_owner.drag_force = 0.2;

	ball_owner.start_hitstop(0.00, dash_self_hitstop, dir * ball_owner.max_speed * speed_boost);

	ball_owner.trail_2d.set_color(ball_owner.color);
	ball_owner.show_trail_for((dash_duration * 2.0) + dash_self_hitstop, additional_trail_length);

	configure_afterimage();
	toggle_opened(true);

	dash_timer = get_tree().create_timer(dash_duration + dash_self_hitstop);
	dash_timer.timeout.connect(stop_dash);
	pass;

func configure_afterimage():
	ball_owner.afterimage.spawn_interval = (dash_duration + dash_self_hitstop) / 50.0;
	ball_owner.afterimage.afterimage_lifetime = (dash_duration + dash_self_hitstop) * 2.0;
	ball_owner.afterimage.active = true;

func kill_dash_timer():
	if(dash_timer.timeout.is_connected(stop_dash)):
		dash_timer.timeout.disconnect(stop_dash);

func dash_hit():
	# print(Utils.pf() + " DASH HIT");
	kill_dash_timer();
	dashing = false;
	dash_hit_registered = true;
	ball_owner.align_weapon_to_velocity = false;
	ball_owner.afterimage.active = false;
	ball_owner.max_speed = pre_dash_max_speed;
	ball_owner.drag_force = pre_dash_drag_force;

func dash_hit_stop():
	# print(Utils.pf() + " STOP DASH (HIT)");
	dash_hit_registered = false;
	ball_owner.ghost = false;
	ball_owner.toggle_ball_ball_collision(true);
	clear_opened();

func stop_dash():
	# print(Utils.pf() + " STOP DASH (TIMEOUT)");
	dashing = false;
	dash_hit_registered = false;
	ball_owner.toggle_ball_ball_collision(true);
	ball_owner.ghost = false;
	ball_owner.align_weapon_to_velocity = false;
	ball_owner.afterimage.active = false;
	ball_owner.max_speed = pre_dash_max_speed;
	ball_owner.drag_force = pre_dash_drag_force;
	toggle_opened(false);
	pass;

func reset_dash(dir:Vector2):
	# print(Utils.pf() + " Reset Dash");
	stop_dash();
	start_dash(dir);

func toggle_opened(s:bool):
	if(!s && block_closing):
		print("BLOCKED CLOSING")
		return;

	ball_owner.block_weapon_rot = false;

	sprite_2d.visible = !s;
	closed_hitbox.collider.set_deferred("disabled", s);
	opened.visible = s;
	scissors_opened_hitbox.collider.set_deferred("disabled", !s);
	weapon_opened = s;

	if(!s):
		closed_hitbox.weapon_clash_cd_elapsed -= 0.15;

func dash_hit_snip_2(other:BattleBall, kb:Vector2):
	AudioManager.play_sfx(sfx_dash_snip, "SFX");
	opened.texture = hit_attack_texture;
	other.affect_health(-dash_damage / 2, ball_owner);
	other.hitflash(hitstop);
	scale_stat();

	ball_owner.lock_position(false);
	other.lock_position(false);

	ball_owner.accumulated_forces = -kb;
	other.accumulated_forces = kb;

	# print("Snip check : " + str(ball_owner.accumulated_forces) + " // " + str(other.accumulated_forces));

func clear_opened():
	# print(Utils.pf() + " CLEAR OPENED");
	opened.texture = hit_attack_base_texture;
	block_closing = false;
	toggle_opened(false);

func reset():
	dash_damage = base_dash_damage;
	super.reset();

func set_battleblock_modifiers():
	super.set_battleblock_modifiers();

	ball_owner.gravity_strength /= 3.5;
	ball_owner.relative_bounce_boost = 0.3;
