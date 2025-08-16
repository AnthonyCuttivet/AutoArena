class_name MatchSettings extends Resource

@export var skip_intro: bool = false;
@export var before_start_delay: float = 3.0;
@export var tiktok_kid_mode: bool = false;
@export var floow_goal: Vector2i = Vector2i(0, 0);
@export var game_mode: String = "default";
@export var skip_countdown: bool = false;
@export var bgm: AudioStream;
@export var bgm_offset: float;
@export var bgm_fade_in: float = 5.0;
@export var result_bgm: AudioStream;
@export var is_question_img: bool = false;
@export var question_img: Texture2D;
@export_multiline var question: String = "NULL";
@export var hide_question: bool = false;
@export var question_audio: AudioStream;
@export var round_duration: float;
@export var match_power: int;
@export var balls_settings: Array[BallSettings];
@export var match_length_target: float = 40.0;

@export var new_floows: Array[String];
