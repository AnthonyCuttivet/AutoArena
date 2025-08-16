class_name VictoryScreen extends Control

@export var anim_player: AnimationPlayer;
@onready var p1_name_label: RichTextLabel = $FakeBall1/Name/NameLabel
@onready var p1_fire: FireRoot = $FakeBall1/FireRoot
@onready var p1_sprite: Sprite2D = $FakeBall1/Sprite2D
@onready var p1_trail: Line2D = $FakeBall1/Sprite2D/Trail
@onready var p2_name_label: RichTextLabel = $FakeBall2/Name/NameLabel
@onready var p2_fire: FireRoot = $FakeBall2/FireRoot
@onready var p2_sprite: Sprite2D = $FakeBall2/Sprite2D
@onready var p2_trail: Line2D = $FakeBall2/Sprite2D/Trail
@onready var question: RichTextLabel = $Question
@onready var question_img: TextureRect = $QuestionIMG
@onready var answer_label: RichTextLabel = $AnswerLabel
@onready var sliding_message: Sliding = $SlidingMessage

@onready var floow_bar: TextureProgressBar = $MarginCRules/VBoxContainer/FollowerGoal/HealthBar/BarLeft/HealthBar/MarginContainer/MainBar
@onready var floow_count: RichTextLabel = $MarginCRules/VBoxContainer/FollowerGoal/HealthBar/BarLeft/HealthBar/MarginContainer/MainBar/CurrentFloow
@onready var floow_goal: RichTextLabel = $MarginCRules/VBoxContainer/Goal

var game_manager: GameManager = null;
var winner: int = -1;

func init(gm: GameManager):
	game_manager = gm;

	if (game_manager.match_settings.game_mode != "default"): return ;

	var ball_1: Ball = gm.balls[0];
	var ball_2: Ball = gm.balls[1];

	p1_name_label.text = ball_1.settings.player_name;
	p1_name_label.self_modulate = ball_1.settings.player_color;
	p1_fire.set_fire_color(ball_1.settings.player_color);
	p1_sprite.self_modulate = ball_1.settings.player_color;
	p1_trail.default_color = ball_1.settings.player_color;

	p2_name_label.text = ball_2.settings.player_name;
	p2_name_label.self_modulate = ball_2.settings.player_color;
	p2_fire.set_fire_color(ball_2.settings.player_color);
	p2_sprite.self_modulate = ball_2.settings.player_color;
	p2_trail.default_color = ball_2.settings.player_color;

	question.visible = !gm.match_settings.is_question_img;
	question_img.visible = gm.match_settings.is_question_img;

	question.text = gm.match_settings.question;
	question_img.texture = gm.match_settings.question_img;

	sliding_message.set_duration();

	var floow: Vector2i = game_manager.match_settings.floow_goal;
	# var floow: Vector2i = game_manager.match_settings.floow_goal + (Vector2i.RIGHT * game_manager.match_settings.new_floows.size());
	floow_bar.value = ((floow.x * 1.0 / floow.y * 1.0) * 100);
	floow_count.text = floow_count.text % [str(floow.x), str(floow.y)];
	floow_goal.text = floow_goal.text % str(floow.y);

func start(_winner: int):
	winner = _winner;
	answer_label.scale = Vector2(0.0, 1.0);
	self.position = Vector2.ZERO;
	answer_label.text = game_manager.balls[_winner].settings.player_name;
	answer_label.self_modulate = game_manager.balls[_winner].settings.player_color;

	anim_player.animation_finished.connect(show_winner);

	anim_player.play("victory");

func show_winner(_anim: String):
	var next_anim: StringName = "p1_victory" if winner == 0 else "p2_victory";

	anim_player.animation_finished.disconnect(show_winner);
	anim_player.play(next_anim);
	sliding_message.set_active();
