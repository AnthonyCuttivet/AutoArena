class_name HUD extends Control

@export var player_huds: Array[PlayerHUD];
@export var game_manager: GameManager;

@export_group("Feedbacks")
@export var health_under_catch_up_duration: float = 0.2;
@export var combo_up_scale: float = 1.1;
@export var combo_up_duration: float = 0.5;
@export var players_damage_point: Array[Node2D];
@export var countdown_move: float = 100.0;
@export var countdown_min_scale: float = 0.2;

@onready var timer_label: RichTextLabel = $MarginCRoot/TopModule/Timer/Timer/TimerLabel
@onready var round_label: RichTextLabel = $MarginCRoot/TopModule/Timer/Round/RoundLabel
@onready var countdown: Control = $MarginCRoot/Countdown
@onready var countdown_label: RichTextLabel = $MarginCRoot/Countdown/CountdownLabel
@onready var damage: HUDDamage = $MarginCRoot/TopModule/Damage
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

@onready var floow_bar: TextureProgressBar = $MarginCRules/VBoxContainer/FollowerGoal/HealthBar/BarLeft/HealthBar/MarginContainer/MainBar
@onready var floow_count: RichTextLabel = $MarginCRules/VBoxContainer/FollowerGoal/HealthBar/BarLeft/HealthBar/MarginContainer/MainBar/CurrentFloow
@onready var floow_goal: RichTextLabel = $MarginCRules/VBoxContainer/Goal
@onready var new_follower_name_label: RichTextLabel = $MarginCRules/NewFollowers/NewFollowerNameLabel
@onready var new_followers_container: Control = $MarginCRules/NewFollowers
@onready var follower_goal: Control = $MarginCRules/VBoxContainer/FollowerGoal

var update_timer: bool = false;
var udpate_countdown: bool = false;
var new_follower_index: int = 0;
var current_follower_bar_value: Vector2i = Vector2i.ZERO;

func _ready() -> void:
	EventBus.match_setup.connect(on_match_setup);
	EventBus.combo_changed.connect(on_combo_changed);
	EventBus.health_changed.connect(on_health_changed);
	EventBus.match_started.connect(_on_match_started);
	EventBus.start_countdown.connect(on_countdown_started);
	EventBus.ball_got_low_health.connect(set_low_health);

	init_hud();

func init_hud():
	for i in player_huds.size():
		var player_hud: PlayerHUD = player_huds[i];

		player_hud.health_main_bar.value = 100;
		player_hud.health_under_bar.value = 100;
		player_hud.player_combo_value.text = "0";
		player_hud.player_combo_value.visible = false;
		player_hud.player_combo.visible = false;
		player_hud.fire.visible = false;
		player_hud.low_health_label.visible = false;
		pass

	timer_label.text = "30";
	round_label.text = "ROUND 1";
	damage.visible = false;
	countdown_label.visible = false;

	if (game_manager.match_settings.game_mode == "circle"):
		player_huds[0].visible = false;
		player_huds[1].visible = false;
		new_followers_container.visible = false;
		follower_goal.visible = false;

	new_follower_name_label.text = new_follower_name_label.text % game_manager.match_settings.new_floows[new_follower_index];
	set_follower_bar_value(Vector2i(0, game_manager.match_settings.floow_goal.y));

func _process(_delta: float) -> void:
	if (udpate_countdown):
		if (!countdown.visible): countdown.visible = true;
		countdown_label.text = str(game_manager.get_timer() + 1);

	if (update_timer):
		timer_label.text = str(game_manager.get_timer());

func on_match_setup():
	for i in game_manager.balls.size():
		var player_hud: PlayerHUD = player_huds[i];
		var ball: Ball = game_manager.balls[i];
		player_hud.player_name_label.text = ball.settings.player_name;
		player_hud.player_color_notch.color = ball.settings.player_color;
		player_hud.hp_value.text = str(ball.settings.max_health);
		pass
	pass ;

func on_countdown_started():
	udpate_countdown = true;
	countdown_feedback();

func get_ball(id: int):
	return game_manager.balls[id];

func on_combo_changed(player_id: int):
	var combo: int = get_ball(player_id).combo;
	var combo_value_label: RichTextLabel = player_huds[player_id].player_combo_value;
	var combo_label: RichTextLabel = player_huds[player_id].player_combo;
	var fire: FireRoot = player_huds[player_id].fire;

	combo_value_label.visible = combo > 0;
	combo_label.visible = combo > 0;
	fire.visible = combo >= 1;

	if (combo == 0):
		return ;

	combo_value_label.text = str(combo);
	combo_up_changed_feedback(combo_value_label, combo_label);
	combo_fire_feedback(combo, fire);

func on_health_changed(player_id: int, dmg: int):
	var player_hud: PlayerHUD = player_huds[player_id];
	var ball: Ball = get_ball(player_id);

	var damage_base_pos: Vector2 = damage.damage_label.global_position;
	damage.damage_label.text = "-" + str(dmg);

	player_hud.hp_value.text = str(ball.health);
	player_hud.health_main_bar.value = ((ball.health * 1.0) / (ball.settings.max_health * 1.0)) * 100.0;
	damage.damage_label.position = players_damage_point[player_id].position;
	damage.visible = true;

	var tween: Tween = create_tween();
	tween.parallel().tween_property(player_hud.health_under_bar, "value", player_hud.health_main_bar.value, health_under_catch_up_duration).set_trans(Tween.TRANS_CUBIC);
	tween.tween_property(damage, "visible", false, 0).set_delay(health_under_catch_up_duration);
	tween.tween_property(damage.damage_label, "position", damage_base_pos, 0);
	tween.play();

func _on_match_started():
	udpate_countdown = false;
	countdown.visible = false;
	update_timer = true;

func combo_up_changed_feedback(value_label: RichTextLabel, combo_label: RichTextLabel):
	var tween: Tween = create_tween();
	var duration: float = combo_up_duration / 2.0;

	tween.set_parallel(true);
	tween.tween_property(value_label, "scale", Vector2.ONE * combo_up_scale, duration).set_ease(Tween.EASE_OUT);
	tween.tween_property(combo_label, "scale", Vector2.ONE * combo_up_scale, duration).set_ease(Tween.EASE_OUT);
	tween.tween_property(value_label, "scale", Vector2.ONE, duration).set_ease(Tween.EASE_IN).set_delay(duration);
	tween.tween_property(combo_label, "scale", Vector2.ONE, duration).set_ease(Tween.EASE_IN).set_delay(duration);

	tween.play();

func combo_fire_feedback(combo: int, fire: FireRoot):
	if (combo < 1):
		return ;

	# combo -= 9;

	fire.scale = Vector2.ONE + (Vector2.ONE * combo * 0.03);
	fire.set_intensity(0.1 * combo);

func on_damaged_feedback(player_id: int, dmg: int):
	var DAMAGE_COMBO_MOVE: Vector2 = Vector2(-80.0, 30.0);
	var DAMAGE_COMBO_MOVE_DURATION: float = 0.05;
	var FINAL_DAMAGE_MOVE_DURATION: float = 0.05;

	var player1_hud: PlayerHUD = player_huds[0];
	var player2_hud: PlayerHUD = player_huds[1];

	var damage_goal_pos: Vector2 = players_damage_point[player_id].global_position;
	damage.damage_label.text = str(dmg);

	var combo1_base_pos: Vector2 = player1_hud.player_combo_value.position;
	var combo2_base_pos: Vector2 = player2_hud.player_combo_value.position;
	var damage_base_pos: Vector2 = damage.damage_label.global_position;

	var damage_combo_move_2: Vector2 = DAMAGE_COMBO_MOVE;
	damage_combo_move_2.y = (-DAMAGE_COMBO_MOVE.y);

	var tween: Tween = create_tween();

	tween.parallel().tween_property(player1_hud.player_combo_value, "position", combo1_base_pos + DAMAGE_COMBO_MOVE, DAMAGE_COMBO_MOVE_DURATION).set_trans(Tween.TRANS_ELASTIC);
	tween.tween_property(player2_hud.player_combo_value, "position", combo2_base_pos + damage_combo_move_2, DAMAGE_COMBO_MOVE_DURATION).set_trans(Tween.TRANS_ELASTIC);
	# tween.tween_property(damage, "visible", true, 0);
	# tween.parallel().tween_property(player1_hud.player_combo_value, "visible", false, 0).set_delay(0.2);
	# tween.tween_property(player2_hud.player_combo_value, "visible", false, 0);
	tween.parallel().tween_property(player1_hud.player_combo_value, "position", combo1_base_pos, 0);
	tween.tween_property(player2_hud.player_combo_value, "position", combo2_base_pos, 0);
	tween.tween_property(damage.damage_label, "global_position", damage_goal_pos, FINAL_DAMAGE_MOVE_DURATION);
	# tween.tween_property(damage, "visible", false, 0);
	tween.tween_property(damage.damage_label, "global_position", damage_base_pos, 0);
	tween.tween_callback(on_health_changed.bind(player_id));

	tween.play();

func countdown_feedback():
	var tween: Tween = create_tween();

	countdown_label.self_modulate.a = 0.0;
	countdown_label.position.x -= countdown_move;
	countdown_label.visible = true;
	countdown_label.scale = Vector2.ONE * countdown_min_scale;

	if (!game_manager.match_settings.skip_intro):
		game_manager.play_sound("321go", "321GO");

	tween_countdown_number(tween, 0.25, 0.0, 0.75, "3");
	tween_countdown_number(tween, 0.25, 1.0, 1.75, "2");
	tween_countdown_number(tween, 0.25, 2.0, 2.75, "1");

	tween.finished.connect(start_new_followers_anim);

	tween.play();

func tween_countdown_number(tween: Tween, duration: float, delay_in: float, delay_out: float, _sound: String):
	# tween.parallel().tween_callback(game_manager.play_sound.bind(sound)).set_delay(delay_in + duration);
	tween.parallel().tween_property(countdown_label, "self_modulate:a", 1.0, duration).set_delay(delay_in);
	tween.parallel().tween_property(countdown_label, "position:x", countdown_label.position.x + countdown_move, duration).set_delay(delay_in);
	tween.parallel().tween_property(countdown_label, "scale", Vector2.ONE, duration).set_delay(delay_in);

	tween.parallel().tween_property(countdown_label, "self_modulate:a", 0.0, duration).set_delay(delay_out);
	tween.parallel().tween_property(countdown_label, "position:x", countdown_label.position.x + countdown_move * 2, duration).set_delay(delay_out);
	tween.parallel().tween_property(countdown_label, "scale", Vector2.ONE * countdown_min_scale, duration).set_delay(delay_out);

	tween.parallel().tween_property(countdown_label, "position:x", countdown_label.position.x - countdown_move, 0).set_delay(delay_out + duration);
	tween.parallel().tween_property(countdown_label, "scale", Vector2.ONE * countdown_min_scale, 0).set_delay(delay_out + duration);

func set_low_health(player_id: int):
	var player_hud: PlayerHUD = player_huds[player_id];

	player_hud.hp_value.self_modulate = Color(1.0, 0.0, 0.0);
	player_hud.low_health_label.visible = true;

func set_follower_bar_value(v: Vector2i):
	current_follower_bar_value = v;
	floow_count.text = str(v.x) + "/" + str(v.y);
	#floow_goal.text = (floow_goal.text % str(v.y));
	animate_new_follower_bar(((v.x * 1.0 / v.y * 1.0) * 100));

func add_to_bar():
	set_follower_bar_value(current_follower_bar_value + Vector2i(1, 0));

	if (new_follower_index == game_manager.match_settings.new_floows.size() - 1):
		new_followers_container.visible = false;
		return ;

	new_follower_index += 1;
	new_follower_name_label.text = new_follower_name_label.text % game_manager.match_settings.new_floows[new_follower_index];

func start_new_followers_anim():
	set_follower_bar_value(game_manager.match_settings.floow_goal);

func animate_new_follower_bar(v: float):
	var tween: Tween = create_tween();
	tween.tween_property(floow_bar, "value", v, 0.5).set_ease(Tween.EASE_IN);
	tween.tween_property(floow_count, "theme_override_font_sizes/normal_font_size", 150, 0.15).set_ease(Tween.EASE_IN);
	tween.tween_property(floow_count, "theme_override_font_sizes/normal_font_size", 70, 0.15).set_ease(Tween.EASE_IN);

	# tween.finished.connect(reset_follower_bar_to_0);

func reset_follower_bar_to_0():
	set_follower_bar_value(game_manager.match_settings.floow_goal);
