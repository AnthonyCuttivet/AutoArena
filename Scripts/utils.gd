class_name Utils

static func generate_random_ball_settings(settings: BallSettings, total_power: int) -> BallSettings:
	settings.total_power = total_power;

	var random_results: Array[int];
	var rand_max: int = total_power;

	for i in range(settings.attributes_count - 1):
		random_results.append(randi_range(0, rand_max));
		rand_max -= random_results[i];
		pass

	random_results.append(rand_max);
	random_results.shuffle();

	settings.other_ball_nudge_force_ratio += settings.other_ball_nudge_force_ratio_unit * random_results[0];
	settings.combo_acceleration += settings.combo_acceleration_unit * random_results[1];
	settings.base_speed += settings.base_speed_unit * random_results[2];
	settings.max_speed_multiplier += settings.max_speed_multiplier_unit * random_results[3];
	settings.max_health += settings.max_health_unit * random_results[4];

	settings.max_speed = settings.base_speed * settings.max_speed_multiplier;
	# settings.size = (settings.max_health * 1.0) / 50.0;

	return settings;

static func apply_settings(ball: Ball, new_settings: BallSettings):
	ball.settings = new_settings;
	ball.root.scale = Vector2.ONE * new_settings.size;

static func spawn_ball(ball_prefab: PackedScene, settings: BallSettings, parent: Node, pos: Vector2) -> Ball:
	var ball: Ball = ball_prefab.instantiate();
	Utils.apply_settings(ball, settings);
	parent.add_child(ball);
	ball.global_position = pos;
	return ball;

static func spawn_ball_gravity(ball_prefab: PackedScene, parent: Node, pos: Vector2) -> BallGravity:
	var ball: BallGravity = ball_prefab.instantiate();
	parent.add_child(ball);
	ball.position = pos;
	return ball;

static func affect_health(ball: Ball, amount: int):
	if (ball.is_invincible || Utils.get_other_ball(ball).is_invincible):
		return ;

	ball.health = clamp(ball.health + amount, 0, ball.settings.max_health);

	if (ball.is_low_health()):
		EventBus.ball_got_low_health.emit(ball.player_id);

	if (ball.health == 0):
		ball.on_death();
		Utils.get_other_ball(ball).reset_combo();
		Utils.get_other_ball(ball).start_invinsibility(999999);
		Utils.get_other_ball(ball).apply_central_impulse(-ball.linear_velocity.normalized() * ball.get_current_max_speed());
		EventBus.ball_dead.emit(ball.player_id);
		EventBus.camera_trigger_shake.emit(150.0);

static func hitflash(ball: Ball, duration: float):
	var tween = ball.get_tree().create_tween().set_parallel(true);
	tween.tween_property(ball.sprite, "material:shader_parameter/flash_intensity", 1, 0);
	tween.chain().tween_property(ball.sprite, "material:shader_parameter/flash_intensity", 0, 0).set_delay(duration);
	await tween.finished;
	pass ;

static func trigger_shake(target: Node, shake_strength: float, shake_fade: float):
	var shaker: Shaker = load(Components.shaker).instantiate();
	target.add_child(shaker);
	shaker.shake_strength = shake_strength;
	shaker.shake_fade = shake_fade;

static func queue_free_after_anim(_anim_name: StringName, object: Node):
	object.queue_free();

static func spawn_text_indicator(parent: Node, text: String, spawn_pos: Vector2, color: Color = Color.WHITE):
	var dmg_indicator: DamageIndicator = load(Components.damage_indicator).instantiate();
	dmg_indicator.global_position = spawn_pos;
	parent.add_child(dmg_indicator);

	dmg_indicator.rich_text_label.text = "[color=#" + color.to_html() + "]" + text + "[/color]";
	dmg_indicator.animation_player.animation_finished.connect(queue_free_after_anim.bind(dmg_indicator));

static func get_other_ball(me: Ball) -> Ball:
	for ball in me.get_tree().get_nodes_in_group("BALL"):
		if (ball != me):
			return ball;
		pass

	return null;

static func get_random_color() -> Color:
	return Color.from_hsv(
		randf_range(0.0, 0.1), # HUE
		randf_range(0.2, 0.6), # SATURATION
		randf_range(0.0, 1.0), # BRIGHTNESS
	);

static func shoot_projectile(projectile_prefab:PackedScene, ball_owner:BattleBall, rotation:float, parent:Node2D, speed:float = -1.0, pierce:int = -1, bounces:int = -1) -> Projectile:
	var p:Projectile = projectile_prefab.instantiate();
	p.global_position = parent.global_position;
	p.rotation = rotation;
	p.scale = ball_owner.weapon_slot.scale * ball_owner.root.scale;
	p.init(ball_owner, speed, pierce, bounces);
	parent.get_tree().root.call_deferred("add_child", p);
	return p;

static func spawn_projectile(projectile_prefab:PackedScene, ball_owner:BattleBall, position:Vector2, rotation:float, parent:Node2D, speed:float = -1.0, pierce:int = -1, bounces:int = -1) -> Projectile:
	var p:Projectile = projectile_prefab.instantiate();
	p.global_position = position;
	p.rotation = rotation;
	p.scale = ball_owner.weapon_slot.scale * ball_owner.root.scale;
	p.init(ball_owner, speed, pierce, bounces);
	parent.get_tree().root.call_deferred("add_child", p);
	return p;

static func convert_time_to_string(time: float) -> String:
	var hours: int = int(time / (60.0 * 60.0))
	var minutes: int = int(time / 60.0) % 60
	var seconds: int = int(time) % 60
	var miliseconds: int = int(time * 1000.0) % 1000
	var string: String = "%02d\"%03d" % [seconds, miliseconds]
	if minutes > 0 or hours > 0:
		string = string.insert(0, ("%02d'" if hours > 0 else "%d'") % minutes)
	if hours > 0:
		string = string.insert(0, "%d:" % hours)
	return string

static func format_number_with_dots(number: int) -> String:
	var num_str: String = str(abs(number))
	var result: String = ""
	var count: int = 0

	for i in range(num_str.length() - 1, -1, -1):
		result = num_str[i] + result
		count += 1
		if count % 3 == 0 and i != 0:
			result = "," + result

	if number < 0:
		result = "-" + result

	return result

static func scale_number(ball:BattleBall):
	match ball.scaling_type:
		Enums.SCALING.LINEAR:
			ball.scaling_damage = Scalings.linear(ball.scaling_damage);
		Enums.SCALING.PRIME:
			ball.scaling_damage = Scalings.prime(ball.scaling_index);
			ball.scaling_index += 1;
		Enums.SCALING.FIBONACCI:
			ball.scaling_damage = Scalings.fibonacci(ball.scaling_index);
			ball.scaling_index += 1;
		Enums.SCALING.POWERS_2:
			ball.scaling_damage *= 2;
			pass;
		Enums.SCALING.TRIANGULAR:
			ball.scaling_damage = Scalings.triangular(ball.scaling_index);
			ball.scaling_index += 1;
			pass;
		Enums.SCALING.SQUARE:
			ball.scaling_damage = pow(ball.scaling_damage, 2) if ball.scaling_damage > 1 else 2;
			pass;
		Enums.SCALING.CUBE:
			pass;
		Enums.SCALING.LOG:
			ball.scaling_damage = Scalings.log_(ball.scaling_index) * 10;
			ball.scaling_index += 1;
			pass;
		Enums.SCALING.EXP:
			pass;
		Enums.SCALING.FACTORIAL:
			ball.scaling_damage = Scalings.factorial(ball.scaling_index);
			ball.scaling_index += 1;
			pass;
		Enums.SCALING.ROULETTE:
			ball.scaling_damage += Scalings.random(36);

	ball.update_scaling_stat_text();


static func pf() -> String:
	return "["+str(Engine.get_frames_drawn())+"]";

static func format_float(value: float, decimals: int = 2) -> String:
	var factor = pow(10, decimals)
	var rounded = round(value * factor) / factor
	# Convert to string and enforce fixed decimal places
	var s = str(rounded)

	# Force trailing zeros if missing
	if "." in s:
		var parts = s.split(".")
		while parts[1].length() < decimals:
			parts[1] += "0"
		s = parts[0] + "." + parts[1]
	else:
		# Add ".00" if there was no decimal part
		s += "." + "0".repeat(decimals)

	return s

static func smooth_rotation(current: float, target: float, speed: float, delta: float) -> float:
	return lerp_angle(current, target, speed * delta);

static func sample_curve(curve:Curve, r:float) -> float:
	return curve.sample(r);

static func arrange_in_fan(nodes: Array, center: Vector2, base_angle_rad: float, spread_rad: float, radius: float) -> void:
	# base_angle in radians, spread in radians
	if nodes.size() == 0:
		return

	var step = 0.0
	if nodes.size() > 1:
		step = spread_rad / float(nodes.size() - 1)

	var start_angle = base_angle_rad - spread_rad * 0.5

	for i in range(nodes.size()):
		var angle = start_angle + step * i
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		nodes[i].position = pos
		nodes[i].rotation = angle

static func weighted_pick(distribution: Array[MCBlockSettings]) -> MCBlockSettings:
	var total_weight := 0
	for d in distribution:
		total_weight += d.weight;

	var r := randi_range(0, total_weight - 1)
	for d in distribution:
		r -= d.weight;
		if r < 0:
			return d
	return distribution.back() # fallback
