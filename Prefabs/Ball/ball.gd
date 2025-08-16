class_name Ball extends RigidBody2D


@onready var arrow: Node2D = $CollisionShape2D/Arrow
@onready var sprite: Sprite2D = $CollisionShape2D/Sprite2D
@onready var invincibility_sprite: Sprite2D = $CollisionShape2D/InvincibilitySprite
@onready var fire: FireRoot = $CollisionShape2D/FireRoot
@onready var trail: Trail2D = $Trail
@onready var character_img: Sprite2D = $CollisionShape2D/Sprite2D/Sprite2D2

@export var root: Node2D;

var low_health_percent_combo_bonus: float = 0.3;

var player_id: int = -1;
var settings: BallSettings = null;
var spin_arrow_speed: float = 0.0;

# --- State
var is_invincible: bool = false;
var invincibility: Elapser = Elapser.new();
var combo: int = 0;
var health: int = 0;
var hitstop: Elapser = Elapser.new();
var before_hitstop_velocity: Vector2 = Vector2.ZERO;
var reset_speed: bool = false;
var other_ball: Ball = null;
var force_stop: bool = false;

func _ready() -> void:
	connect_events();
	init_ball();
	pass ;

func _integrate_forces(state):
	if (force_stop):
		linear_velocity = linear_velocity.normalized();
		return ;

	var current_max_speed: float = get_current_max_speed();
	var velocity: Vector2 = state.get_linear_velocity();

	if (reset_speed):
		reset_speed = false;
		state.set_linear_velocity(velocity.normalized() * settings.base_speed);

	if velocity.length() > current_max_speed:
		state.set_linear_velocity(velocity.normalized() * current_max_speed)

func _physics_process(delta: float) -> void:
	if (spin_arrow_speed > 0.0):
		arrow.rotation += spin_arrow_speed * delta;

	if (is_invincible):
		if (invincibility.update(delta)):
			stop_invincibility();

	if (hitstop.duration > 0.0):
		if (hitstop.update(delta)):
			stop_hitstop();

	fire.rotation = linear_velocity.angle() + deg_to_rad(-90.0);

func connect_events():
	body_entered.connect(_on_body_entered);

func init_ball():
	health = settings.max_health;
	sprite.self_modulate = settings.player_color;
	character_img.texture = settings.player_splash;

	arrow.visible = false;
	invincibility_sprite.visible = false;
	apply_combo_to_fire(0);
	fire.set_fire_color(settings.player_color);
	trail.set_color(settings.player_color);

func _on_body_entered(body):
	if (body is Ball):
		handle_other_ball_collision(body);
	elif (body.is_in_group("RESET_ZONE")):
		handle_reset_zone_collision();
	else:
		handle_combo_collision();

func start_arrow_spin(speed: float, preset_arrow_rot: float = -1.0):
	if (preset_arrow_rot == -1.0):
		arrow.rotation_degrees = randf_range(0.0, 360.0);
	else:
		arrow.rotation_degrees = preset_arrow_rot;

	spin_arrow_speed = speed * randf_range(0.9, 1.1);
	arrow.visible = true;

func launch():
	arrow.visible = false;
	var impulse: Vector2 = arrow.transform.x.rotated(deg_to_rad(90.0)) * settings.base_speed;
	apply_impulse(impulse);

func lock_arrow():
	spin_arrow_speed = 0.0;

func start_visible_invincibility(duration: float):
	start_invinsibility(duration);
	invincibility_sprite.visible = true;

func start_invinsibility(duration: float):
	invincibility.reset();
	invincibility.duration = duration;
	is_invincible = true;

func stop_invincibility():
	is_invincible = false;
	invincibility_sprite.visible = false;

func get_current_max_speed() -> float:
	return settings.max_speed;

func get_damage(other: Ball) -> int:
	return combo - other.combo;

func get_speed() -> float:
	return linear_velocity.length();

func increment_combo():
	add_combo(1);
	apply_impulse(linear_velocity.normalized() * get_current_max_speed() * settings.combo_acceleration);

	if (get_other_ball() == null): return ;
	var dir_to_other_ball: Vector2 = (get_other_ball().global_position - self.global_position).normalized();
	apply_central_impulse(dir_to_other_ball * get_speed() * settings.other_ball_nudge_force_ratio);

func reset_combo():
	if (is_invincible): return ;
	set_combo(0);

func inflict_damage(amount: int) -> bool:
	if (amount == 0): return false;
	Utils.affect_health(self, -amount);
	EventBus.player_damaged.emit(player_id, amount);
	EventBus.health_changed.emit(player_id, amount);
	return true;

func handle_other_ball_collision(other_ball: Ball):
	if (get_other_ball().is_invincible): return ;

	# EventBus.play_sound.emit("hit");

	var dmg: int = get_damage(get_other_ball());

	if (dmg > 0):
		get_other_ball().inflict_damage(dmg);
	else:
		self.inflict_damage(-dmg);


	# print("Ball collision [" + str(dmg) + "] " + self.name + "(" + str(combo) + ") -> " + str(other_ball.name) + "(" + str(other_ball.combo) + ")");

	on_hit(self, dmg);

	reset_combo();
	get_other_ball().reset_combo();
	pass ;

func handle_reset_zone_collision():
	reset_combo();
	set_deferred("reset_speed", true);
	Utils.spawn_text_indicator(self.get_tree().root, "RESET", self.global_position, Color("cc425e"));
	pass ;

func handle_combo_collision():
	increment_combo();
	EventBus.play_player_sfx.emit(player_id, "bounce");
	pass ;

func on_hit(other: Ball, multiplier: int):
	var v: float = 0.055;
	self.start_hitstop(v);
	other.start_hitstop(v);
	Utils.hitflash(other, v * 1.25);
	Utils.trigger_shake(other, 10.0, 2.0);
	EventBus.camera_trigger_shake.emit((multiplier + 1) * 5.0);

func set_freeze(v: bool):
	freeze = v;
	if (!v):
		start_invinsibility(0.1);
		if (get_other_ball() == null): return ;
		var dir_to_other_ball: Vector2 = (get_other_ball().global_position - self.global_position).normalized();
		apply_impulse(-dir_to_other_ball * settings.max_speed);

func start_hitstop(duration: float):
	before_hitstop_velocity = linear_velocity;
	hitstop.duration = duration;
	call_deferred("set_freeze", true);

func stop_hitstop():
	hitstop.duration = 0.0;
	hitstop.reset();
	call_deferred("set_freeze", false);

func is_low_health() -> bool:
	return health <= settings.max_health * low_health_percent_combo_bonus;

func add_combo(v: int) -> int:
	if (v < 0 && is_invincible):
		return 0;

	if (is_low_health()):
		v *= 2;

	set_combo(clamp(combo + v, 0, 9999));
	return v;

func set_combo(v: int):
	combo = v;
	apply_combo_to_fire(v);
	EventBus.combo_changed.emit(player_id);

func get_other_ball() -> Ball:
	if (other_ball == null):
		other_ball = Utils.get_other_ball(self);

	return other_ball;

func apply_combo_to_fire(v: int):
	if (v < 10):
		fire.visible = false;
		return ;

	if (!fire.visible):
		fire.visible = true;

	fire.set_intensity(0.05 * v);

func apply_force_stop():
	start_invinsibility(9999999);
	reset_combo();
	force_stop = true;

func on_death():
	print(settings.player_name + " Dead");
	self.visible = false;
	root.set_deferred("disabled", true);
	start_invinsibility(9999999);
	apply_force_stop();
	reset_combo();
