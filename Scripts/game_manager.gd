class_name GameManager extends Node

@export var match_settings: MatchSettings;

@export var balls_amount: int = 2;
@export var arenas: Dictionary[StringName, Arena];
@export var ball_prefab: PackedScene;
@export var ball_gravity_prefab: PackedScene;
@export var ball_skins: Array[Texture];
@export var steps_duration: Array[float];
@export var ball_arrow_spin_speed: float = 15.0;
@export var start_game_invincibility_duration: float = 5.0;
@export var note_duration: Elapser;
@export var sound_volume: float = -20.0;
@export var after_death_delay: Elapser;
@export var fxs: Array[GPUParticles2D];
@export var death_fxs: Array[GPUParticles2D];
@export var win_fxs: Array[GPUParticles2D];
@export var chromatic_aberration: ColorRect;
@export var black_over: ColorRect;
@export var obs: OBSWebsocket;
@export var victory_screen_timeout: Elapser;
@export var sfx: Array[AudioStream];
@export var sfx_hit: Array[AudioStream];
@export var fx_hit_prefab: PackedScene;

@export var sounds: Dictionary[String, AudioStream];

@export var hud: HUD;
@export var midi_player: MidiPlayer;
@export var fighters_screen: VSScreen;
@export var victory_screen: VictoryScreen;

var is_init: bool = false;
var step: int = -1;
var step_elapsed: float = 0.0;
var balls: Array[Ball];
var song_elapsed: float = 0;
var in_fighters_screen: bool = false;
var in_battle: bool = false;
var in_victory_screen: bool = false;
var in_after_death: bool = false;
var dead_ball_id: int = -1;
var next_sfx_index: int = 0;
var next_sfx_hit_index: int = 0;

var in_before_start: bool = false;
var before_start_delay: Elapser = Elapser.new();
var debug_match_elapsed: float = 0.0;

var bgm_player_path: NodePath;

func _ready() -> void:
	connect_events();

func _process(delta: float):
	if (match_settings.before_start_delay > 0.0):
		in_before_start = true;
		before_start_delay.duration = match_settings.before_start_delay;
		if (before_start_delay.elapsed == 0.0):
			obs.establish_connection();

	if (in_before_start):
		if (before_start_delay.update(delta)):
			in_before_start = false;
			black_over.visible = false;
		else:
			return ;

	if (!is_init):
		init();

		if (!match_settings.skip_intro):
			start_fighters_screen();
		else:
			black_over.visible = false;
			if (match_settings.game_mode == "default"):
				setup_battle();
				start_match("");

	if (in_after_death):
		if (after_death_delay.update(delta)):
			match_over(Utils.get_other_ball(balls[dead_ball_id]).player_id);
		return ;

	if (in_victory_screen):
		if (victory_screen_timeout.update(delta)):
			obs.send_command("StopRecord");
			return ;
		return ;

	if (!in_battle): return ;

	for ball in balls:
		ball.settings.other_ball_nudge_force_ratio += (1.0 / match_settings.match_length_target) * delta;
		pass

	step_elapsed += delta;

	if (step > 3):
		return ;

	if (step_elapsed >= steps_duration[step]):
		trigger_step();

	if (step == 0 && step_elapsed >= 1.0):
		for i in balls_amount:
			balls[i].lock_arrow();


	debug_match_elapsed += delta;
	# print(debug_match_elapsed);

	# if (midi_player.playing):
	# 	if (note_duration.update(delta)):
	# 		midi_player.stop();

	pass

func connect_events():
	EventBus.player_damaged.connect(on_player_damaged);
	EventBus.play_sound.connect(play_sound);
	EventBus.play_player_sfx.connect(play_player_sfx);
	EventBus.ball_dead.connect(ball_dead);
	EventBus.match_over.connect(match_over);
	EventBus.set_chromatic_aberration.connect(set_chromatic_aberration);
	EventBus.stop_record.connect(stop_record);

func init():
	obs.send_command("StartRecord");
	is_init = true;
	hud.game_manager = self;

func start_fighters_screen():
	in_fighters_screen = true;
	fighters_screen.init(self, match_settings.balls_settings[0], match_settings.balls_settings[1]);

func setup_battle():
	for arena in arenas:
		arenas[arena].visible = false;

	var arena: Arena = arenas[match_settings.game_mode]
	arena.visible = true;

	if (match_settings.game_mode == "default"):
		for i in match_settings.balls_settings.size():
			var ball_settings: BallSettings = match_settings.balls_settings[i];
			balls.append(Utils.spawn_ball(ball_prefab, Utils.generate_random_ball_settings(ball_settings, match_settings.match_power), arena, arena.spawns[i].global_position));
			balls[i].player_id = i;
			hud.player_huds[i].fire.set_fire_color(balls[i].settings.player_color);
			pass
	elif (match_settings.game_mode == "circle"):
		arenas["circle"].on_ready(self);

	if (match_settings.bgm != null):
		bgm_player_path = play_sound_direct(match_settings.bgm, "BGM", match_settings.bgm_offset, match_settings.bgm_fade_in);

	victory_screen.init(self);
	EventBus.match_setup.emit();


func start_match(_s: String):
	EventBus.match_setup.emit();

	if (match_settings.hide_question):
		fighters_screen.question.visible = false;

	in_fighters_screen = false;
	in_battle = true;
	trigger_step();

func increment_game_step():
	step += 1;
	step_elapsed = 0.0;

func trigger_step():
	if (match_settings.game_mode != "default"): return ;

	if (step == -1):
		EventBus.start_countdown.emit();
		for i in balls_amount:
			balls[i].start_arrow_spin(ball_arrow_spin_speed);
			balls[i].name = "BALL " + str(i);

	if (step == 0):
		for i in balls_amount:
			# balls[i].start_visible_invincibility(start_game_invincibility_duration);
			balls[i].launch();

		EventBus.match_started.emit();

	increment_game_step();

func get_timer() -> int:
	if (step > 3): return 0;
	return int(steps_duration[step] - step_elapsed);

func play_sound(_name: String, bus: String = "Master"):
	if (_name == "bumper"):
		play_sfx();
		return ;

	AudioManager.play_sound(sounds[_name], sound_volume, bus);

func play_player_sfx(id: int, _name: String):
	var settings: BallSettings = match_settings.balls_settings[id];
	AudioManager.play_sound(settings.player_audio_bounce if _name == "bounce" else settings.player_audio_hit, sound_volume, "SFX");


func play_sound_direct(stream: AudioStream, bus: String = "Master", offset: float = 0.0, fade_in: float = 0.0) -> NodePath:
	return AudioManager.play_sound(stream, sound_volume, bus, offset, fade_in);

func on_player_damaged(_player_id: int, _amount: int):
	var fx: GPUParticles2D = fx_hit_prefab.instantiate();
	fx.global_position = balls[_player_id].global_position;
	fx.emitting = true;
	fx.modulate = balls[_player_id].settings.player_color;
	fx.rotation = balls[_player_id].linear_velocity.angle();
	add_child(fx);
	play_player_sfx(Utils.get_other_ball(balls[_player_id]).player_id, "hit");
	pass ;

func play_sfx():
	if (sfx.size() == 0):
		return ;
	play_sound_direct(sfx[next_sfx_index], "SFX");
	next_sfx_index = randi_range(0, sfx.size() - 1);

func play_sfx_hit():
	if (sfx_hit.size() == 0):
		return ;
	play_sound_direct(sfx_hit[next_sfx_hit_index], "SFX_HIT");
	next_sfx_hit_index = (next_sfx_hit_index + 1) % sfx_hit.size();

func play_note():
	print("Play note " + str(song_elapsed));
	midi_player.play(song_elapsed);
	song_elapsed += note_duration.duration;
	pass ;

func ball_dead(id: int):
	var fx_id = 2 if balls[id].settings.neutral_fx else id;

	if (fx_id == 2):
		death_fxs[fx_id].modulate = balls[id].settings.player_color;

	death_fxs[fx_id].global_position = balls[id].global_position;
	death_fxs[fx_id].emitting = true;
	in_battle = false;
	in_after_death = true;
	dead_ball_id = id;

func match_over(winner: int):
	in_after_death = false;
	in_victory_screen = true;
	balls[winner].apply_force_stop();
	victory_screen.start(winner);
	# AudioManager.kill_audio_player(bgm_player_path);
	# play_sound_direct(match_settings.result_bgm, "BGM");
	pass ;

func cam_shake(shake_strength: float):
	EventBus.camera_trigger_shake.emit(shake_strength);

func play_winner_audio():
	play_sound_direct(Utils.get_other_ball(balls[dead_ball_id]).settings.player_audio_hit);

func play_winner_fx():
	var winner_id: int = Utils.get_other_ball(balls[dead_ball_id]).player_id;
	var fx_id: int = 2 if balls[winner_id].settings.neutral_fx else winner_id;

	if (fx_id == 2):
		win_fxs[fx_id].modulate = balls[winner_id].settings.player_color;

	win_fxs[fx_id].emitting = true;

func set_chromatic_aberration(v: float):
	var tween: Tween = create_tween();
	var duration: float = 0.5;

	tween.parallel().tween_property(chromatic_aberration, "material:shader_parameter/r_displacement", Vector2(v, v), duration / 2.0);
	tween.parallel().tween_property(chromatic_aberration, "material:shader_parameter/b_displacement", Vector2(-v, v), duration / 2.0);
	tween.parallel().tween_property(chromatic_aberration, "material:shader_parameter/r_displacement", Vector2(0.2, 0.2), duration / 2.0).set_delay(duration / 2.0);
	tween.parallel().tween_property(chromatic_aberration, "material:shader_parameter/b_displacement", Vector2(-0.2, -0.2), duration / 2.0).set_delay(duration / 2.0);

func stop_record():
	obs.send_command("StopRecord");
	obs.break_connection();
