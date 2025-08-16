class_name VSScreen extends Control

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

@onready var player_1_splash: TextureRect = $Player1Sprite
@onready var player_1_label: RichTextLabel = $Player1Sprite/Name/NameLabel
@onready var player_2_splash: TextureRect = $Player2Sprite
@onready var player_2_label: RichTextLabel = $Player2Sprite/Name/NameLabel
@onready var ball_1_fire: FireRoot = $FakeBall1/FireRoot
@onready var ball_1_sprite: Sprite2D = $FakeBall1/Sprite2D
@onready var ball_1_trail: Line2D = $FakeBall1/Sprite2D/Trail
@onready var ball_2_fire: FireRoot = $FakeBall2/FireRoot
@onready var ball_2_sprite: Sprite2D = $FakeBall2/Sprite2D
@onready var ball_2_trail: Line2D = $FakeBall2/Sprite2D/Trail
@onready var vs_logo: TextureRect = $VSLogo
@onready var question: RichTextLabel = $Question
@onready var question_img: TextureRect = $QuestionIMGWrapper/QuestionIMG

@onready var sliding_message: Sliding = $SlidingMessage

var game_manager: GameManager = null;
var step: int = -1;
var bs_1: BallSettings = null;
var bs_2: BallSettings = null;

func init(gm: GameManager, s1: BallSettings, s2: BallSettings):
	var tiktok: bool = gm.match_settings.tiktok_kid_mode;

	if (!tiktok):
		connect_events();

	game_manager = gm;

	set_sliding_message_starting_duration();

	self.position = Vector2.ZERO;

	if (tiktok):
		game_manager.play_sound_direct(game_manager.match_settings.question_audio);
		game_manager.setup_battle();
		animation_player.animation_finished.connect(game_manager.start_match);

	animation_player.play("INIT" if !tiktok else "tiktok_speed_intro");

	bs_1 = s1;
	bs_2 = s2;
	apply_fake_balls();

	question.visible = !gm.match_settings.is_question_img;
	question_img.visible = gm.match_settings.is_question_img;

	question.text = gm.match_settings.question;
	question_img.texture = gm.match_settings.question_img;

	if (!tiktok):
		animation_player.animation_finished.connect(increment_step);


func increment_step(_s: String):
	step += 1;
	trigger_step();

func trigger_step():
	match (step):
		0: # Play question audio
			game_manager.play_sound_direct(game_manager.match_settings.question_audio);
			sliding_message.set_active();
		1: # Play question animation
			animation_player.play("question_to_top");
		2: # Play Fighter 1
			animation_player.play("fighter_screen_1");
		3: # Play Versus
			animation_player.play("versus");
		4: # Play Fighter 2
			animation_player.play("fighter_screen_2");
		5: # Play Versus to Game
			game_manager.setup_battle();
			animation_player.animation_finished.connect(game_manager.start_match);
			animation_player.play("versus_to_game");

func play_sound(_sound: String):
	pass ;

func apply_fake_balls():
	player_1_label.text = bs_1.player_name;
	ball_1_fire.set_fire_color(bs_1.player_color);
	ball_1_sprite.self_modulate = bs_1.player_color;
	ball_1_trail.default_color = bs_1.player_color;

	player_2_label.text = bs_2.player_name;
	ball_2_fire.set_fire_color(bs_2.player_color);
	ball_2_sprite.self_modulate = bs_2.player_color;
	ball_2_trail.default_color = bs_2.player_color;

func on_audio_finished(_instance_id: int):
	increment_step("");

func connect_events():
	AudioManager.audio_finished.connect(on_audio_finished);

func set_sliding_message_starting_duration():
	sliding_message.starting_duration = game_manager.match_settings.question_audio.get_length();
	sliding_message.starting_duration += animation_player.get_animation("question_to_top").length;
	sliding_message.starting_duration += animation_player.get_animation("fighter_screen_1").length;
	sliding_message.starting_duration += animation_player.get_animation("versus").length;
	sliding_message.starting_duration += animation_player.get_animation("fighter_screen_2").length;
	sliding_message.starting_duration += animation_player.get_animation("versus_to_game").length;
