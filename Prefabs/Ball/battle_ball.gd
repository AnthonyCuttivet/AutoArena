class_name BattleBall extends RigidBody2D

@export var debug_mode:bool = false;
@export var debug_hitstop:bool = false;
@export var debug_physics:bool = false;
@export var weapon_settings:WeaponSettings;
@export var start_dir:Vector2;
# @export var speed:float = 30.0;
@export var health:int = 100;
@export var base_weapon_rotation:float = 0.0;
@export var no_weapon:bool;
@export var color:Color;
@export var base_target_attraction:float = 1.0;

@export var team:int = 0;
@export var clash_invincibility:float = 0.6;

@export var dead:bool = false;
@export var stop:bool = false;
@export var is_boss:bool = false;

@export var weapon:Weapon;
@export var align_weapon_to_velocity:bool = false;
@export var lose_hp_per_s:int = 0;

# --- Tweakable settings ---
@export var max_speed: float = 2200.0
@export var min_horizontal: float = 200.0
@export var gravity_strength: float = 1400.0
@export var drag_force: float = 0.02
@export var bounce_boost: float = 250.0;
@export var relative_bounce_boost:float = 0.0;
@export var acceleration:float = 1.0;
@export var knockback_resistance:float = 1.0;
@export var ghost:bool = false;
@export var lock:bool = false;

# --- Push Duel ---
@export var custom_ball_name:String = "";
@export var scaling_type:Enums.SCALING;
@export var replace_health:bool = false;
@export var use_value_separator: bool = false;
@export var sfx_scale:SFX;
@export var use_white_name_color:bool = false;

@onready var hp_text: RichTextLabel = $Root/HP_Text;
@onready var circle: Sprite2D = $Root/Circle
@onready var weapon_slot: Node2D = $Root/WeaponSlot
@onready var root: CollisionShape2D = $Root
@onready var trail_2d: Trail2D = $Root/Trail
@onready var afterimage: Afterimage = $Root/Afterimage

var main:Main = null;
var is_init:bool = false;
var time_scale:float = 1.0;
var physics_time_scale:float = 1.0;
var accumulated_forces:Vector2 = Vector2.ZERO;
var invincible_for:float = false;
var hit_pos:Vector2 = Vector2.ZERO;
var current_target_attraction:float = 0.0;
var end_game:bool = false;

var prev_linear_velocity:Vector2 = Vector2.ZERO;
var target:BattleBall = null;

var hitstop_remaining:float = 0.0;
var absolute_hitstop:bool = false;

var name_text:DynamicText = null;
var ui_sprite:TextureRect = null;
var details_text:DynamicText = null;
var stat_text:DynamicText = null;

var vel_to_apply:Vector2 = Vector2.ZERO;
var lose_hp_timer:Timer = null;

var drift_dir: float = 1.0 # left (-1) or right (+1)
var base_drag_force:float = 0.0;
var base_max_speed:float = 0.0;

var lock_pos:bool = false;
var locked_pos:Vector2;
var block_weapon_rot:bool = false;

var scaling_index:int = 0;
var scaling_damage:int = 1;

var base_root_scale:float = 0.0;
var nerfed_speed:float = 0.0;

# var aled:bool = false;

func ready() -> void:
	spawn_weapon();
	circle.self_modulate = color;

	if(use_white_name_color):
		hp_text.self_modulate = Color.WHITE;

	update_health_text();
	is_init = true;

	sleeping = false;
	can_sleep = false;
	linear_damp = 0.0;
	angular_damp = 0.0;
	gravity_scale = 0.0;
	drift_dir = -1.0 if randf() < 0.5 else 1.0
	base_drag_force = drag_force;
	base_max_speed = max_speed;
	base_root_scale = root.scale.x;

	current_target_attraction = base_target_attraction;

	# Ensure perfect bounce
	if physics_material_override:
		physics_material_override.friction = 0.0;
		physics_material_override.bounce = 1.0;

	if(debug_mode):
		freeze = true;

	if(stop):
		freeze = true;

	if(replace_health):
		hp_text.text = custom_ball_name;

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if(stop): return;

	var vel := linear_velocity

	# --- Manual gravity ---
	vel.x -= gravity_strength * state.step * acceleration;

	# --- Keep minimal sideways motion alive ---
	if abs(vel.y) < min_horizontal:
		vel.y += drift_dir * acceleration * 30.0  # gentle nudge

	# --- Soft speed cap (drag-based) ---
	var speed = vel.length()
	if speed > max_speed:
		# Apply drag proportional to how far past max we are
		var excess_ratio = (speed - max_speed) / max_speed
		vel *= 1.0 - (drag_force * excess_ratio)

	linear_velocity = vel * physics_time_scale;

func _physics_process(delta: float) -> void:
	if(debug_physics):
		debug_collisions();
	if(!is_init): return;
	if(weapon == null): return;
	if(dead): return;
	if(lock_pos):
		freeze = true;
		global_position = locked_pos;
		return;

	if(hitstop_remaining <= 0.0 && freeze && time_scale >= 0.0 && accumulated_forces != Vector2.ZERO):
		set_deferred("freeze", false);
		apply_impulse(accumulated_forces);
		accumulated_forces = Vector2.ZERO;

	if(invincible_for > 0.0):
		invincible_for -= delta;

	if(align_weapon_to_velocity):
		# DebugDraw2D.arrow_vector(global_position, linear_velocity.normalized() * 50, Color.RED, 1.0, 1.0);
		weapon_slot.rotation = linear_velocity.normalized().angle() - deg_to_rad(90.0);
	elif(!block_weapon_rot):
		weapon_slot.rotate(deg_to_rad(360.0 * weapon.rotation_speed * weapon.rotation_direction * time_scale) * delta);

	# speed += delta;
	# min_speed += delta;
	max_speed += 2 * delta;

	# if(trail.visible && linear_velocity.length() <= max_speed):
	# 	trail.visible = false;

func _process(delta: float) -> void:
	if(hitstop_remaining >= 0.0):
		hitstop_remaining -= delta;
		if(hitstop_remaining <= 0.0):
			stop_hitstop();

func start(m:Main, dir:Vector2):
	main = m;
	if(debug_mode):return;
	stop = false;
	freeze = false;
	show_trail(false);
	trail_2d.default_color = color;
	trail_2d.default_color.a = 0.75;
	# min_speed = min_speed + randf_range(min_speed * -0.2, min_speed * 0.2);
	# max_speed = min_speed + randf_range(max_speed * -0.2, max_speed * 0.2);
	apply_impulse(dir * max_speed);

	if(lose_hp_per_s > 0):
		set_hp_lost_per_s(lose_hp_per_s);

func start_duel():
	if(debug_mode):return;
	stop = false;
	freeze = false;
	show_trail(false);
	trail_2d.default_color = color;
	trail_2d.default_color.a = 0.75;

func spawn_weapon() -> Weapon:
	if(weapon_settings == null): return;
	if(weapon_settings.weapon_prefab == null): return;

	var w:Weapon = weapon_settings.weapon_prefab.instantiate();
	weapon_slot.scale = Vector2.ONE * weapon_settings.base_size;
	weapon_slot.add_child(w);
	weapon = w;
	w.position.x += weapon_settings.offset;
	w.init(weapon_settings, self);
	weapon_slot.rotation = deg_to_rad(base_weapon_rotation);
	if(debug_mode): weapon_slot.global_rotation_degrees = 0.0;
	return w;

func update_health_text():
	hp_text.text = str(health);

func update_stat_text(no_bump:bool = false):
	if(stat_text == null): return;

	var s:String = weapon.get_custom_stat_format();

	if(s == ""):
		if(weapon_settings.scaling_stat_float):
			s = Utils.format_float(weapon.scaling_stat_value, 1);
		else:
			s = str(int(weapon.scaling_stat_value));

	stat_text.format([weapon_settings.stat_scale_name, s]);
	if(!no_bump):
		stat_text.bump(1.08, 0.08);

func update_scaling_stat_text():
	if(stat_text == null): return;

	# var s:String = "";

	# if(weapon_settings.scaling_stat_float):
	# 	s = str("%0.2f" % scaling_damage);
	# else:
	# 	s = str(scaling_damage);

	stat_text.format([weapon_settings.stat_scale_name, Utils.format_number_with_dots(scaling_damage)]);
	stat_text.bump(1.08, 0.08);

func affect_health(v:int, from:BattleBall, silent:bool = false):
	if(is_invincible()):
		print(Utils.pf() + " Prevented " + str(v) + " thanks to INVINCIBILITY");
		return;
	health += v;
	update_health_text();

	if(v < 0 && !silent):
		EventBus.ball_damaged.emit(get_instance_id(), abs(v), from.get_instance_id());

	if(health <= 0 && !dead):
		main.set_time_scale(0.1, 0.5);
		death();

func start_hitstop(t:float, duration: float, knockback:Vector2 = Vector2.ZERO, override:bool = true, absolute:bool = false):
	#Add override bool
	# if(freeze && !debug_mode): return;

	if(override && hitstop_remaining > 0.0):
		override_hitstop(t,duration, knockback);
		return;

	if(debug_hitstop):
		print(Utils.pf() + " Hitstop Start for " + str(duration) + "s");

	if(weapon.rot_speed_bounce_boost):
		weapon.rotation_speed = weapon_settings.base_rotation_speed;

	time_scale = t;

	prev_linear_velocity = linear_velocity;
	accumulated_forces = knockback;

	call_deferred("set_freeze", true);
	# set_freeze(true);

	hitstop_remaining = duration;
	absolute_hitstop = absolute;

func override_hitstop(t:float, duration:float, knockback:Vector2 = Vector2.ZERO):
	if(absolute_hitstop):
		return;

	time_scale = t;
	hitstop_remaining = duration;
	accumulated_forces = knockback;

func stop_hitstop():
	time_scale = 1.0;
	absolute_hitstop = false;
	call_deferred("set_freeze", false);

func set_freeze(v: bool):
	freeze = v;

	if(!v):
		if(debug_mode):return;

		if(debug_hitstop):
			print(Utils.pf() + " Hitstop Stop (" + str(accumulated_forces)+")");

		if(accumulated_forces == Vector2.ZERO || is_boss):
			accumulated_forces = prev_linear_velocity;

		if(knockback_resistance != 1.0):
			accumulated_forces = prev_linear_velocity.normalized() * base_max_speed * knockback_resistance;
		elif(accumulated_forces.length() < base_max_speed):
			accumulated_forces = linear_velocity.normalized() * base_max_speed;

		# print(name + " Hitstop stop impulse " + str(accumulated_forces.length()));

		apply_impulse(accumulated_forces);

		accumulated_forces = Vector2.ZERO;

func _on_body_entered(other: Node) -> void:
	if(other.is_in_group("BALL")):
		if(ghost): return;
		EventBus.ball_bounce_other_ball.emit(get_instance_id(), other.get_instance_id());

	EventBus.ball_bounce.emit(get_instance_id());

	if(!other.is_in_group("DRYWALL")):
		var dir = (global_position - other.global_position).normalized();
		if(relative_bounce_boost > 0.0):
			bounce_boost = max_speed * relative_bounce_boost;
		linear_velocity += dir * bounce_boost;  # Knockback boost

	if(other.is_in_group("WALL")):
		# linear_velocity += ((main.attraction_point.global_position - global_position).normalized() * linear_velocity.length() * center_pull_strength);
		# apply_impulse(-linear_velocity.normalized() * max_speed * 0.15);
		drift_dir *= -1;

		if(weapon.rot_speed_bounce_boost):
			weapon.rotation_speed += 0.01;

	# var angle_tweak = deg_to_rad(randf_range(-3.0, 3.0));
	# linear_velocity = linear_velocity.rotated(angle_tweak);

	pass;

func hitflash(d:float):
	var tween = create_tween().set_parallel(true);
	tween.tween_property(circle, "material:shader_parameter/flash_intensity", 1, 0);
	tween.chain().tween_property(circle, "material:shader_parameter/flash_intensity", 0, 0).set_delay(d);

func is_in_same_team(other: BattleBall) -> bool:
	if(other == null): return false;
	return team == other.team;

func add_invincibility(v:float):
	invincible_for += v;

func is_invincible()->bool:
	return invincible_for > 0.0;

func death():
	EventBus.ball_dead.emit(get_instance_id());
	lock_pos = false;
	dead = true;
	visible = false;
	set_process(false);
	set_deferred("global_position", Vector2.ONE * 9999);
	set_deferred("freeze", true);
	sleeping = true;
	root.set_deferred("disabled", true);
	for hitbox:Hitbox in weapon.hitboxes:
		hitbox.set_deferred("monitorable", false);
		hitbox.set_deferred("monitoring", false);
		pass

	if(main != null):
		update_ui_name(main.dead_ui_color);
		update_ui_details(main.dead_ui_color);
		update_ui_sprite(main.dead_ui_color);
		update_ui_stat(main.dead_ui_color);

func lose_hp_timeout():
	if(self.health == 1): return;
	affect_health(-1,self, true);

func show_trail_for(d:float, additionnal_length:int = 0):
	trail_2d.length += additionnal_length;
	show_trail(true);
	get_tree().create_timer(d).timeout.connect(show_trail.bind(false, additionnal_length));

func show_trail(b:bool, additionnal_length:int = 0):
	trail_2d.length -= additionnal_length;
	trail_2d.visible = b;
	if(!b):
		trail_2d.points.clear();

func debug_collisions():
	var space_state = get_world_2d().direct_space_state

	# Query overlapping bodies (using the shape of this rigidbody)
	for i in range(get_shape_owners().size()):
		var owner_id = get_shape_owners()[i]
		var shape_count = shape_owner_get_shape_count(owner_id)

		for j in range(shape_count):
			var shape = shape_owner_get_shape(owner_id, j)
			var shape_transform = shape_owner_get_transform(owner_id)

			var params = PhysicsShapeQueryParameters2D.new()
			params.shape_rid = shape.get_rid()
			params.transform = global_transform * shape_transform
			params.collision_mask = collision_mask

			var results = space_state.intersect_shape(params, 8) # check up to 8 results
			for result in results:
				if result.has("collider"):
					var col = result.collider
					if col != self:
						print(self.name + " Touching: ", col.name, " (", col, ")")

func toggle_ball_ball_collision(s:bool):
	set_collision_mask_value(2, s);

func lock_position(s:bool):
	lock_pos = s;
	if(s):
		locked_pos = self.global_position;

func set_hp_lost_per_s(v:int):
	if(lose_hp_timer == null):
		lose_hp_timer = Timer.new();
		lose_hp_timer.ignore_time_scale = true;
		lose_hp_timer.autostart = true;
		lose_hp_timer.wait_time = 1.0 / v;
		lose_hp_timer.timeout.connect(lose_hp_timeout);
		add_child(lose_hp_timer);

	if(v == 0.0):
		lose_hp_timer.stop();
	else:
		lose_hp_timer.wait_time = 1.0 / v;
		lose_hp_timer.start();

	lose_hp_per_s = v;

func set_physics_time_scale(v: float, d:float):
	var t:Timer = Timer.new();
	t.ignore_time_scale = true;
	t.one_shot = true;;
	t.autostart = true;
	t.wait_time = d;
	t.timeout.connect(func(): physics_time_scale = 1.0; linear_velocity = linear_velocity.normalized() * max_speed; drag_force = base_drag_force);
	get_tree().current_scene.add_child(t);

	physics_time_scale = v;

func update_ui_name(c:Color, t:String = ""):
	if(t == ""):
		name_text.format([weapon_settings.name]);
	else:
		name_text.text = t;

	name_text.self_modulate = c;

func update_ui_sprite(c:Color = Color.WHITE):
	ui_sprite.texture = weapon.sprite_2d.texture;
	ui_sprite.self_modulate = c;

func update_ui_details(c:Color, raw:bool = false):
	if(raw):
		details_text.text = weapon_settings.details;
	else:
		details_text.format([weapon_settings.details]);

	details_text.modulate = c;

func update_ui_stat(c:Color):
	if(!dead):
		stat_text.format([weapon_settings.name]);
	stat_text.self_modulate = c;

func nerf_max_speed(v:float):
	max_speed *= v;
	nerfed_speed = abs(base_max_speed - max_speed);
