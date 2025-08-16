class_name MainPush extends Node2D

@export var devmode:bool = false;
@export var record:bool = false;
@export var obs_delay: float = 1.5;

@export var number_scale:int = 10;
@export var team_names:Array[String];
@export var top_balls:Array[BattleBall];
@export var bot_balls:Array[BattleBall];
@export var block:PushBlock;

@export var top_blocks:Array[BreakBlock];
@export var bot_blocks:Array[BreakBlock];

@export var scale_per_block_destroyed:float = 0.005;
@export var gravity_gain_on_block_destroyed:float = 1.1;

@export var fx_bounce_prefab: PackedScene;
@export var fx_death_prefab: PackedScene;

@export var hit_shake:float = 0.1;
@export var hit_max_shake:float = 0.3;
@export var death_shake:float = 0.2;

@export var sfx_bounce:SFX;
@export var sfx_win:SFX;
@export var sfx_death:SFX;
@export var ve_announcer:SFX;
@export var no_announcer:bool = false;

@onready var obs: OBSWebsocket = $OBS
@onready var camera: Camera = $Camera

@onready var winner_text: DynamicText = $Winner
@onready var name_top: DynamicText = $UI/NameTop
@onready var stat_top: DynamicText = $UI/StatTop
@onready var name_bot: DynamicText = $UI/NameBot
@onready var stat_bot: DynamicText = $UI/StatBot
@onready var finish_line_top_sprite: Sprite2D = $FinishLineTop/FinishLineTopSprite
@onready var finish_line_bot_sprite: Sprite2D = $FinishLineBot/FinishLineBotSprite
@onready var fdp_de_mur: CollisionShape2D = $Walls/WallTop/CollisionShape2D

var balls:Array[BattleBall];
var balls_ids:Dictionary[int, int];
var just_spawned_fxs:Array[GPUParticles2D];
var top_blocks_index:int = 0;
var block_progress_per_team:Dictionary[int,int];

func _ready() -> void:
	if(devmode):
		camera.zoom = Vector2.ONE * 0.5;

	EventBus.ball_bounce.connect(on_ball_bounce);
	EventBus.ball_dead.connect(on_ball_dead);
	EventBus.ball_duel_scale.connect(on_ball_scale);
	EventBus.block_destroyed.connect(on_block_destroyed);
	EventBus.ball_duel_winner.connect(on_winner);

	obs.establish_connection();

	init_balls();
	init_blocks();
	init_ui();

	for i in balls.size():
		balls_ids[balls[i].get_instance_id()] = i;

	var t_record:SceneTreeTimer = get_tree().create_timer(obs_delay);
	var t_start_game:SceneTreeTimer = get_tree().create_timer(obs_delay + 0.4);

	t_record.timeout.connect(start_record);
	t_start_game.timeout.connect(start_game);

func _physics_process(_delta: float) -> void:
	for fx in just_spawned_fxs:
		fx.emitting = true;
		fx.visible = true;
		pass

	just_spawned_fxs.clear();

func start_game():
	if(!no_announcer):
		AudioManager.play_sfx(ve_announcer, "Master");

	for ball in bot_balls:
		ball.gravity_strength *= -1;

	for ball in balls:
		ball.start_duel();

	get_tree().create_timer(0.1).timeout.connect(fdp);


func end_game():
	var t_stop_record:SceneTreeTimer = get_tree().create_timer(5.0);
	t_stop_record.timeout.connect(stop_record);

func init_balls():
	balls.push_back(top_balls[0]);
	balls.push_back(bot_balls[0]);

	for i in top_balls.size():
		top_balls[i].team = 0;
		if(i==0):continue;
		balls.push_back(top_balls[i]);

	for i in bot_balls.size():
		bot_balls[i].team = 1;
		if(i==0):continue;
		balls.push_back(bot_balls[i]);

func get_ball_by_id(id:int) -> BattleBall:
	if(!balls_ids.has(id)):
		return null;

	return balls[balls_ids[id]];

func on_ball_scale(id:int):
	var sfx:SFX = get_ball_by_id(id).sfx_scale;
	if(sfx == null): return;
	scale_all_team_balls_stat(id);
	AudioManager.play_sfx(sfx, "SFX");

func on_ball_bounce(id: int):
	if(!balls_ids.has(id)): return;

	AudioManager.play_sfx(sfx_bounce, "SFX");

	var fx: GPUParticles2D = fx_bounce_prefab.instantiate();
	add_child(fx);
	var ball:BattleBall = get_ball_by_id(id);
	fx.scale = Vector2.ONE * ball.root.scale.x * 10.0;
	fx.global_position = ball.global_position;
	fx.modulate = ball.color;
	fx.modulate.a = 0.5;
	fx.visible = false;
	get_tree().create_timer(0.032).timeout.connect(start_fx.bind(fx));
	# just_spawned_fxs.push_back(fx);

func on_ball_dead(id: int):

	if(!balls_ids.has(id)):
		return;

	for ball in balls:
		ball.start_hitstop(0.01,0.6);

	AudioManager.play_sfx(sfx_death, "SFX", 0.0, 0.0, true);
	EventBus.camera_trigger_shake.emit(death_shake);

	for i in range(6):
		var fx: GPUParticles2D = fx_death_prefab.instantiate();
		var ball:BattleBall = get_ball_by_id(id);
		add_child(fx);
		fx.global_position = ball.global_position + Vector2.ONE * randf_range(-50.0, 50.0);
		fx.modulate = ball.color;
		fx.visible = false;
		just_spawned_fxs.push_back(fx);

	# teams_alive_members[get_ball_by_id(id).team] -= 1;

	# if(teams_alive_members[get_ball_by_id(id).team] <= 0):
	# 	end_game();
	# 	return;

func global_hitstop(d:float):
	for ball in balls:
		ball.start_hitstop(0.00, d);

func init_ui():
	name_top.self_modulate = balls[0].color;
	name_top.format([team_names[0]]);
	balls[0].stat_text = stat_top;
	stat_top.self_modulate = balls[0].color;
	stat_top.format([balls[0].weapon_settings.stat_scale_name, Utils.format_number_with_dots(balls[0].scaling_damage)]);

	name_bot.self_modulate = balls[1].color;
	name_bot.format([team_names[1]]);
	balls[1].stat_text = stat_bot;
	stat_bot.self_modulate = balls[1].color;
	stat_bot.format([balls[1].weapon_settings.stat_scale_name, Utils.format_number_with_dots(balls[1].scaling_damage)]);

	finish_line_top_sprite.self_modulate = balls[0].color;
	finish_line_bot_sprite.self_modulate = balls[1].color;

func init_blocks():
	block_progress_per_team[0] = 0;
	block_progress_per_team[1] = 0;

	for i in top_blocks.size():
		top_blocks[i].main = self;
		top_blocks[i].block_value = pow(number_scale, i);
		top_blocks[i].block_index = i;
		top_blocks[i].team = 0
		top_blocks[i].init();
		if(i == 0):continue;
		top_blocks[i].polygon_2d.color.v = 1 - ((i-1)*0.035);

	for i in bot_blocks.size():
		bot_blocks[i].main = self;
		bot_blocks[i].block_value = pow(number_scale, i);
		bot_blocks[i].block_index = i;
		bot_blocks[i].team = 1;
		bot_blocks[i].init();
		if(i == 0):continue;
		bot_blocks[i].polygon_2d.color.v = 1 - ((i-1)*0.035);

func on_block_destroyed(id:int, block_index:int):
	if(!balls_ids.has(id)):
		return;

	var ball:BattleBall = get_ball_by_id(id);

	ball.root.scale += Vector2.ONE * scale_per_block_destroyed;
	ball.gravity_strength = ball.gravity_strength * gravity_gain_on_block_destroyed;
	ball.max_speed *= gravity_gain_on_block_destroyed;

	var team:int = get_ball_by_id(id).team;
	var arr:Array[BreakBlock] = top_blocks if team == 0 else bot_blocks;
	block_progress_per_team[team] = block_index;
	if(block_progress_per_team[team] == arr.size() - 1):
		get_tree().create_timer(0.4).timeout.connect(func():
			ball.gravity_strength *= 30.0;
			ball.max_speed *= 30.0;
			get_tree().create_timer(1.0).timeout.connect(func():
				ball.gravity_strength /= 30.0;
				ball.max_speed /= 30.0;
			);
		);

func on_winner(id:int):
	AudioManager.play_sfx(sfx_win, "SFX");
	winner_text.modulate = get_ball_by_id(id).color;
	winner_text.format([team_names[get_ball_by_id(id).team]]);
	end_game();

func start_fx(fx:GPUParticles2D):
	fx.emitting = true;
	fx.visible = true;

func scale_all_team_balls_stat(id:int):
	if(!balls_ids.has(id)):
		return;

	var ball:BattleBall = get_ball_by_id(id);
	var team_balls:Array[BattleBall] = top_balls if ball.team == 0 else bot_balls;

	for team_ball in team_balls:
		Utils.scale_number(team_ball);


func fdp():
	fdp_de_mur.set_deferred("disabled", false);

# --------------- OBS RECORD --------------------

func start_record():
	if(record):
		obs.send_command("StartRecord");

func stop_record():
	obs.send_command("StopRecord");
