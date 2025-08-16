class_name ArenaCircle extends Arena

@export_group("Arena Settings")
@export var balls_manager: BallManager;
@export var balls_limit: int = 1000;
@export var starting_balls: int = 2;
@export var gravity: float = 0.3;
@export var circle_radius: float = 300.0;
@export var circle_center: Vector2 = Vector2.ZERO;
@export var gap_angle_start: float = 0.0;
@export var gap_angle_end: float = 0.0;
@export var ball_spawn: int = 2;
@export var ball_out_shake_strength: float = 0.5;
@export var spawn: Node2D;
@export var timer: Elapser;
@export var sfx: Array[AudioStream];
@export var sfx_yes_no: Array[AudioStream] = [null, null];
@export var after_result_duration: Elapser;

@onready var circle: ColorRect = $Env/Circle
@onready var fx_circle_yes: GPUParticles2D = $FX/FXCircleYEs
@onready var fx_circle_no: GPUParticles2D = $FX/FXCircleNO

@export_group("Ball Settings")
@export var ball_radius: float = 17.0;
@export var starting_velocity_x_rnd: Vector2 = Vector2(-10, 10);
@export var starting_velocity_y: float = -300.0;
@export var max_y_vel: float = 9.3;

@export_group("Misc")
@export var ball_gravity_prefab: PackedScene;

@export_group("HUD")
@export var yes_score: RichTextLabel;
@export var no_score: RichTextLabel;
@export var timer_label: RichTextLabel;
@export var rules_label: RichTextLabel;
@export var ball_count_label: RichTextLabel;
@export var yes_result: RichTextLabel;
@export var no_result: RichTextLabel;
@export var timer_parent: ColorRect;
@onready var debug: RichTextLabel = $HUD/Debug

var yes_score_format: String = "NULL";
var no_score_format: String = "NULL";
var timer_format: String = "NULL";

var active_balls_count: int = 0;
var gap_start_rad: float = 0.0;
var gap_end_rad: float = 0.0;
var hole_position: Vector2 = Vector2.ZERO;
var next_sfx_index: int = 0;
var score: Vector2i = Vector2i.ZERO;
var over: bool = false;
var t: float = 0.0;
var can_update: bool = false;
var balls: Array[BallGravity] = [];

func on_ready(gm: GameManager):
	game_manager = gm;

	init_arena();

	for i in range(starting_balls):
		spawn_ball(i % 2);

	can_update = true;

	pass

func _process(delta):
	debug.text = str(active_balls_count) + " balls - " + str(Engine.get_frames_per_second()) + "fps";

	if (over):
		after_result_duration.update(delta);
		if (after_result_duration.is_over()):
			print("OVER");
			EventBus.stop_record.emit();
		return ;

	if (!can_update): return ;

	t += delta;

	update_circle_color();

	timer.update(delta);
	timer_label.text = timer_format.format({"s": str(abs(timer.duration - timer.elapsed)).pad_decimals(1)});

	if (timer.is_over()):
		over = true;
		on_game_over();

	pass

func _physics_process(delta: float):
	if (over): return ;
	for ball in balls:
		ball.update(delta);
		pass

func init_arena():
	gap_start_rad = deg_to_rad(gap_angle_start - 90.0)
	gap_end_rad = deg_to_rad(gap_angle_end - 90.0)
	hole_position = circle_center + Vector2(cos(gap_start_rad), sin(gap_start_rad)) * (circle_radius - ball_radius)

	balls_manager.init_arena(self);

	circle.material.set_shader_parameter("gap_start_deg", gap_angle_start);
	circle.material.set_shader_parameter("gap_end_deg", clamp(gap_angle_end, 0.001, 9999999999));
	no_score_format = no_score.text;
	yes_score_format = yes_score.text;
	no_score.text = no_score_format.format({"s": "0"});
	yes_score.text = yes_score_format.format({"s": "0"});
	timer_format = timer_label.text;
	timer_label.text = timer_format.format({"s": str(timer.duration)});
	rules_label.text = rules_label.text.format({"s": str(ball_spawn)});
	update_ball_count_label(0);

# func spawn_ball(team: int):
# 	if (balls.size() >= balls_limit): return ;
# 	var ball: BallGravity = Utils.spawn_ball_gravity(ball_gravity_prefab, self, spawn.position);
# 	ball.arena = self;
# 	ball.team = team;
# 	var color = Color.RED if team == 0 else Color.GREEN;
# 	ball.init(starting_velocity_x_rnd, starting_velocity_y, color);
# 	update_ball_count_label(1);
# 	balls.append(ball);

func spawn_ball(team: int):
	var vel = Vector2(randf_range(starting_velocity_x_rnd.x, starting_velocity_x_rnd.y), starting_velocity_y)

	balls_manager.add_ball(spawn.position, vel, Color.RED if team == 0 else Color.GREEN, team)
	update_ball_count_label(1);

func add_point(team: int):
	if (team == 0):
		score.x += 1;
		no_score.text = no_score_format.format({"s": str(score.x)});
	else:
		score.y += 1;
		yes_score.text = yes_score_format.format({"s": str(score.y)});

func on_ball_out(ball: BallGravity):
	if (!ball.is_out): return ;
	# EventBus.camera_trigger_shake.emit(ball_out_shake_strength);
	update_ball_count_label(-1);
	add_point(ball.team);
	play_sfx_yes_no(ball.team);
	balls.erase(ball);
	spawn_balls();

func on_game_over():
	for ball in balls:
		ball.kill_ball();
		pass

	balls.clear();

	if (score.x == score.y):
		play_circle_fx(fx_circle_yes);
		play_circle_fx(fx_circle_no);
		show_winner(0);
		show_winner(1);
		return ;

	var fx = fx_circle_no if score.x > score.y else fx_circle_yes;
	var winner: int = 0 if score.x > score.y else 1;
	play_circle_fx(fx);
	show_winner(winner);


func play_circle_fx(fx: GPUParticles2D):
	fx.visible = true;
	fx.emitting = true;
	circle.visible = false;
	ball_count_label.visible = false;
	timer_parent.visible = false;
	rules_label.visible = false;

func update_circle_color():
	circle.material.set_shader_parameter("color", Color.from_hsv(fmod(t / 10.0, 1.0), 1, 1));

func spawn_balls():
	for i in range(ball_spawn):
		spawn_ball(i % 2);

func play_sfx():
	if (game_manager == null or sfx.size() == 0):
		return ;
	game_manager.play_sound_direct(sfx[next_sfx_index], "SFX");
	next_sfx_index = (next_sfx_index + 1) % sfx.size();

func play_sfx_yes_no(team: int):
	if (game_manager == null or sfx_yes_no.size() == 0):
		return ;
	var index: int = 0 if team == 0 else 1;
	game_manager.play_sound_direct(sfx_yes_no[index], "SFX");

func show_winner(team: int):
	var winner_label: RichTextLabel = no_result if team == 0 else yes_result;
	winner_label.visible = true;
	play_sfx_yes_no(team);

func update_ball_count_label(add: int):
	active_balls_count += add;
	ball_count_label.text = str(active_balls_count);

func on_ball_out_optimized(team: int):
	# EventBus.camera_trigger_shake.emit(ball_out_shake_strength);
	update_ball_count_label(-1);
	add_point(team);
	spawn_balls();
	pass
