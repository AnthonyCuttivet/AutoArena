class_name BallSettings extends Resource

@export var player_name: String = "NO_PLAYER_NAME";
@export var player_color: Color = Color.PINK;
@export var player_audio_bounce: AudioStream;
@export var player_audio_hit: AudioStream;
@export var player_splash: Texture;
@export var neutral_fx: bool = false;

@export var base_speed: float = 1000.0;
@export var base_speed_unit: float = 1.0;

@export var max_speed_multiplier: float = 3.0;
@export var max_speed_multiplier_unit: float = 1.0;

@export var combo_acceleration: float = 0.15;
@export var combo_acceleration_unit: float = 1.0;

@export var max_health: int = 30;
@export var max_health_unit: int = 1;

@export var other_ball_nudge_force_ratio: float = 0.3;
@export var other_ball_nudge_force_ratio_unit: float = 1.0;

@export var size_per_max_health_unit: float = 1.0;

var attributes_count: int = 5;
var total_power: int = 100;
var max_speed: float = 3000.0;
var size: float = 1.0;
