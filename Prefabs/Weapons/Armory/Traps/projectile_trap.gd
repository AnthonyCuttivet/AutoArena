class_name ProjectileTrap extends Projectile

@export var move_duration:float = 1.0;
@export var fixed_lifetime:float = 1.0;
@export var arrow_rot_speed_range:Vector2 = Vector2.ZERO;
@export var acceleration_curve:Curve;
@export var arrow:Node2D;
@export var neutral_rot_diff:float = 62.0;
@export var small_arrow_sprite:Sprite2D;

var move_elapsed:float = 0.0;
var fixed_lifetime_elapsed:float = 0.0;
var fixed_dir:Vector2 = Vector2.ZERO;
var position_fixed:bool = false;
var arrow_rot_speed:float = 0.0;
var weapon_traps:WeaponTraps = null;
var timeout:bool = false;
var disabled:bool = true;
var triggered:bool = false;

func init(o:BattleBall, s:float, _p:int = 0, _b:int = 0):
	super.init(o, s);

	weapon_traps = weapon_owner;

	fixed_dir = weapon_owner.global_transform.x;

	if(acceleration_curve != null):
		velocity = fixed_dir * acceleration_curve.sample(0.0) * speed;
	else:
		velocity = fixed_dir * speed;

	rotation_speed = randf_range(arrow_rot_speed_range.x, arrow_rot_speed_range.y);
	var angle_to_center:float = rad_to_deg(fixed_dir.angle_to_point(ball_owner.main.arena_center.global_position));
	angle_to_center += rotation_speed;
	rotation_speed = angle_to_center / move_duration;


func _physics_process(delta: float) -> void:
	weapon_owner = ball_owner.weapon;

	move_elapsed += delta;

	if(!position_fixed):
		var ratio:float = move_elapsed / move_duration;
		velocity = fixed_dir * acceleration_curve.sample(ratio) * speed;
		global_position += velocity * delta;

	if(move_elapsed < move_duration):
		global_rotation_degrees += rotation_speed * delta;
	else:
		position_fixed = true;

		if(fixed_lifetime_elapsed == 0.0):
			disabled = false;
			open_trap();

		fixed_lifetime_elapsed += delta;
		if(!triggered && !timeout && fixed_lifetime_elapsed >= fixed_lifetime):
			timeout = true;
			close_trap();

func _on_projectile_hitbox_area_entered(other: Area2D) -> void:
	if(disabled || triggered): return;

	if(other is Hurtbox && other.ball_owner.team != ball_owner.team):
		triggered = true;
		trigger_trap(other.ball_owner);
		return;

	if(other is Hitbox && other.ball_owner.team != ball_owner.team):
		other.ball_owner.weapon.on_weapon_clash(self, global_position);
		disabled = true;
		close_trap();
		return;

func _on_projectile_hitbox_body_entered(other: Node2D) -> void:
	if(absolute) : return;

	if(other.is_in_group("WALL")):
		position_fixed = true;

	if(other.is_in_group("DEADZONE")):
		destroy();
		return;

# Closed -> neutral -> On hit -> armed -> Closed

func open_trap():
	var grow_size:Vector2 = Vector2.ONE * 1.5;
	var grow_duration:float = 0.1;
	var open_delay:float = 0.03;
	var shrink_duration:float = 0.12;
	var displacement:float = -15.0;

	var t:Tween = create_tween();

	get_tree().create_timer(open_delay).timeout.connect(func():AudioManager.play_sfx(weapon_traps.sfx_trap_trigger));

	t.tween_property(sprite_2d, "scale", grow_size, grow_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);
	t.parallel().tween_property(arrow, "modulate:a", 1.0, open_delay);
	t.parallel().tween_property(sprite_2d, "rotation_degrees", sprite_2d.rotation_degrees + neutral_rot_diff, open_delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);
	t.parallel().tween_property(arrow, "rotation_degrees", arrow.rotation_degrees - neutral_rot_diff, open_delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);
	t.parallel().tween_property(sprite_2d, "texture", weapon_traps.tx_neutral_trap, 0.0).set_delay(open_delay);
	t.parallel().tween_property(self, "global_position:x", global_position.x + displacement, shrink_duration * 0.7).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT);
	t.tween_property(sprite_2d, "scale", Vector2.ONE, shrink_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);


func trigger_trap(ball:BattleBall):
	if(disabled): return;
	var grow_size:Vector2 = Vector2.ONE * 3.0;
	var grow_duration:float = weapon_traps.trap_hit_total_duration * 0.25;
	var armed_delay:float = weapon_traps.trap_hit_total_duration * 0.05;
	var closed_delay:float = weapon_traps.trap_hit_total_duration * 0.5;

	small_arrow_sprite.visible = false;

	var t:Tween = create_tween();

	if(ball != null):
		ball.start_hitstop(0.0, weapon_traps.trap_hit_total_duration);

	get_tree().create_timer(armed_delay).timeout.connect(func():AudioManager.play_sfx(weapon_traps.sfx_trap_trigger));
	get_tree().create_timer(closed_delay).timeout.connect(func():AudioManager.play_sfx(weapon_traps.sfx_trap_closed));

	t.tween_property(sprite_2d, "scale", grow_size, grow_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);
	t.parallel().tween_property(self, "global_position", ball.global_position, 0.0).set_delay(armed_delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);
	t.parallel().tween_property(sprite_2d, "texture", weapon_traps.tx_armed_trap, 0.0).set_delay(armed_delay);
	t.parallel().tween_property(sprite_2d, "texture", weapon_traps.tx_closed_trap, 0.0).set_delay(closed_delay);
	t.tween_callback(weapon_traps.trap_hit_fxs.bind(ball.global_position));
	t.tween_interval(weapon_traps.trap_hit_total_duration * 0.5);
	t.finished.connect(destroy);
	if(ball != null):
		t.finished.connect(trap_hit.bind(ball));

func trap_hit(ball:BattleBall):
	var knockback:Vector2 = global_transform.x;
	weapon_traps.on_trap_hit(ball, self.global_position, knockback, 0.25);

func close_trap():
	var close_delay:float = 0.05;
	var shrink_duration:float = 0.5;

	get_tree().create_timer(shrink_duration / 2.0).timeout.connect(func(): disabled = true);
	var t:Tween = create_tween();

	get_tree().create_timer(close_delay).timeout.connect(func():AudioManager.play_sfx(weapon_traps.sfx_trap_closed));
	t.tween_property(small_arrow_sprite, "self_modulate:a", 0.0, 0.05);
	t.tween_property(sprite_2d, "texture", weapon_traps.tx_closed_trap, 0.0).set_delay(close_delay);
	t.tween_property(sprite_2d, "scale", Vector2.ONE * 0.5, shrink_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(close_delay);
	t.parallel().tween_property(sprite_2d, "self_modulate:a", 0.0, shrink_duration);
	t.finished.connect(destroy);
