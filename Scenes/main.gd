class_name Main extends Node2D

@export var devmode: bool = false;
@export var record:bool = false;
@export var patchnote_mode:bool = false;
@export var patchnote_s_per_page:float = 20.0;
@export var patchnote_pages:Array[RichTextLabel];
@export var new_challenger_mode:bool = false;
@export var new_challenger_camera_fade:float = 15.0;
@export var new_challenger_ball:BattleBall;
@export var time_attack_mode:bool = false;
@export var display_damage_dealt:bool = false;
@export var time_attack_leaderboards:Dictionary[String, TimeAttackLeaderboard];
@export var time_attack_endgame_delay:float = 2.0;
@export var time_attack_ranking_duration:float = 15.0;
@export var free_for_all:bool = false;
@export var _2v2_colors:Array[Color];
@export var tournament_mode:bool = false;
@export var bo3_mode:bool = false;
@export var preset_score:Vector2i;

@export var forced_start_dir:Vector2 = Vector2.ZERO;
@export var dead_ui_color:Color;

@export var balls: Array[BattleBall];
@export var fx_hit_prefab: PackedScene;
@export var fx_death_prefab: PackedScene;
@export var fx_clash:PackedScene;

@export var hit_shake:float = 0.1;
@export var hit_max_shake:float = 0.3;
@export var death_shake:float = 0.2;

@export var sfx_bounce:SFX;
@export var sfx_bounce_boss:SFX;
@export var sfx_death:SFX;
@export var ve_announcer:SFX;
@export var no_announcer:bool = false;

@export var obs_delay: float = 1.5;

@export var earclacks_mode:bool = false;
@export var _1v1_hp:int = 50;
@export var _1v2_hp:int = 75;
@export var attraction_point:Node2D;

# -------------- UI Single Team Player ----------------

@onready var name_left_1p: DynamicText = $UI/Top/CharacterLeft_1p/Character/Name
@onready var sprite_left_1p: TextureRect = $UI/Top/CharacterLeft_1p/Character/Sprite
@onready var details_left_1p: DynamicText = $UI/Top/CharacterLeft_1p/Details
@onready var stat_left_1p: DynamicText = $UI/Bottom/StatLeft_1p

@onready var name_right_1p: DynamicText = $UI/Top/CharacterRight_1p/Character/Name
@onready var sprite_right_1p: TextureRect = $UI/Top/CharacterRight_1p/Character/Sprite
@onready var details_right_1p: DynamicText = $UI/Top/CharacterRight_1p/Details
@onready var stat_right_1p: DynamicText = $UI/Bottom/StatRight_1p

# -------------- UI Team 2 Player ----------------

@onready var name_left_1_2p: DynamicText = $UI/Top/CharactersLeft_2p/Character1/Name
@onready var sprite_left_1_2p: TextureRect = $UI/Top/CharactersLeft_2p/Character1/Sprite
@onready var details_left_1_2p: DynamicText = $UI/Top/CharactersLeft_2p/Details1
@onready var stat_left_1_2p: DynamicText = $UI/Bottom/StatLeft1_2p

@onready var name_left_2_2p: DynamicText = $UI/Top/CharactersLeft_2p/Character2/Name
@onready var sprite_left_2_2p: TextureRect = $UI/Top/CharactersLeft_2p/Character2/Sprite
@onready var details_left_2_2p: DynamicText = $UI/Top/CharactersLeft_2p/Details2
@onready var stat_left_2_2p: DynamicText = $UI/Bottom/StatLeft2_2p

# ------ #

@onready var name_right_1_2p: DynamicText = $UI/Top/CharactersRight_2p/Character1/Name
@onready var sprite_right_1_2p: TextureRect = $UI/Top/CharactersRight_2p/Character1/Sprite
@onready var details_right_1_2p: DynamicText = $UI/Top/CharactersRight_2p/Details1
@onready var stat_right_1_2p: DynamicText = $UI/Bottom/StatRight1_2p

@onready var name_right_2_2p: DynamicText = $UI/Top/CharactersRight_2p/Character2/Name
@onready var sprite_right_2_2p: TextureRect = $UI/Top/CharactersRight_2p/Character2/Sprite
@onready var details_right_2_2p: DynamicText = $UI/Top/CharactersRight_2p/Details2
@onready var stat_right_2_2p: DynamicText = $UI/Bottom/StatRight2_2p

# -------------- Containers ----------------

@onready var container_1v1_left: VBoxContainer = $UI/Top/CharacterLeft_1p
@onready var container_1v1_right: VBoxContainer = $UI/Top/CharacterRight_1p
@onready var container_2v2_left: VBoxContainer = $UI/Top/CharactersLeft_2p
@onready var container_2v2_right: VBoxContainer = $UI/Top/CharactersRight_2p

# ------ #

@onready var vs: RichTextLabel = $UI/Top/VS
@onready var winner_text: DynamicText = $UI/Winner

@onready var obs: OBSWebsocket = $OBS
@onready var camera: Camera = $Camera

@onready var bg_earclacks: ColorRect = $BG_Earclacks
@onready var bg: ColorRect = $BG
@onready var arena_bg: ColorRect = $Walls/ColorRect
@onready var author: RichTextLabel = $author
@onready var version: RichTextLabel = $Version
@onready var wallbot: Polygon2D = $Walls/WallBot/CollisionShape2D/Polygon2D
@onready var walltop: Polygon2D = $Walls/WallTop/CollisionShape2D/Polygon2D
@onready var wallleft: Polygon2D = $Walls/WallLeft/CollisionShape2D/Polygon2D
@onready var wallright: Polygon2D = $Walls/WallRight/CollisionShape2D/Polygon2D
@onready var crt: ColorRect = $CRT

@onready var patch_note: Control = $PatchNote
@onready var new_challenger: Control = $NewChallenger
@onready var animation_player: AnimFuncs = $NewChallenger/AnimationPlayer
@onready var arena_center: Node2D = $Center
@onready var balls_container: Node2D = $Balls

@onready var time_attack_container: VBoxContainer = $UI/Top/TimeAttackContainer
@onready var time_attack: RichTextLabel = $UI/Top/TimeAttackContainer/TimeAttack
@onready var ta_timer: RichTextLabel = $UI/Top/TimeAttackContainer/TATimer
@onready var ta_record: DynamicText = $UI/Top/TARecord

@onready var damage_dealt_container: VBoxContainer = $UI/Bottom/DamageDoneContainer
@onready var damage_dealt_text: DynamicText = $UI/Bottom/DamageDoneContainer/Damage_Done
@onready var time_attack_leaderboard_ui: TimeAttackLeaderboardUI = $TimeAttackLeaderboard
@onready var bo3_score_ui: DynamicText = $UI/Top/BO3Score

@onready var special_effects_parent: Node2D = $SpecialEffectsParent
@onready var projectiles_bg_parent: Node2D = $ProjectilesBGParent

@onready var confettis: Node2D = $Confettis
@onready var chromatic_aberration: ColorRect = $ChromaticAberration

@onready var tournament_container: Control = $Tournament
@onready var bracket: TournamentBracket = $Tournament/Bracket

var balls_ids: Dictionary[int, int];
var teams_alive_members: Dictionary[int, int];
var balls_alive_count:int = 0;

var current_patchnote_page:int = 0;
var patchnote_timer:Timer = null;

var _1v1_spots:Array[Vector2];
var _1v2_spots:Array[Vector2];
var _2v2_spots:Array[Vector2];
var _4v_ffa_spots:Array[Vector2];

var just_spawned_fxs:Array[GPUParticles2D];

var time_attack_elapsed:float = 0.0;

var started:bool = false;
var process_timer:bool = false;

var damage_dealt:Dictionary[int,int];
var bo3_score:Dictionary[int, int];

func _ready() -> void:
	if(devmode):
		obs_delay = 0.0;
		camera.zoom = Vector2(.5,.5);

	if(patchnote_mode):
		patch_note.visible = true;
		patchnote_timer = Timer.new();
		patchnote_timer.wait_time = patchnote_s_per_page;
		patchnote_timer.timeout.connect(show_next_patchnote_page);
		get_tree().root.add_child.call_deferred(patchnote_timer);
		patchnote_timer.autostart = true;

	EventBus.ball_damaged.connect(on_ball_damaged);
	EventBus.ball_dead.connect(on_ball_dead);
	EventBus.ball_bounce.connect(sfx_play_bounce);
	EventBus.ball_weapon_clash.connect(on_ball_clash);
	EventBus.set_chromatic_aberration.connect(set_chromatic_aberration);

	if(earclacks_mode):
		set_earclacks_mode();

	obs.establish_connection();

	if(time_attack_mode || balls.size() == 4):
		display_damage_dealt = true;

	setup_fight();

	init_ui();

	teams_alive_members[0] = 0;
	teams_alive_members[1] = 0;

	if(free_for_all):
		teams_alive_members[2] = 0;
		teams_alive_members[3] = 0;

	for i in range(balls.size()):
		balls_ids[balls[i].get_instance_id()] = i;
		teams_alive_members[balls[i].team] += 1;
		if(i==0 && balls.size() > 1):
			balls[0].target = balls[1];
		else:
			balls[i].target = balls[0];

		init_damage_dealt(balls[i].get_instance_id());

	if(display_damage_dealt):
		update_damage_dealt_UI();

	if(bo3_mode):
		init_bo3_score();

	if(tournament_mode):
		no_announcer = true;
		for ball in balls:
			ball.stop = true;

	if(new_challenger_mode):
		for ball in balls:
			ball.stop = true;

		balls[0].weapon.rotation_speed = 0.0;
		balls[0].weapon_slot.global_rotation_degrees = 60.0;

		no_announcer = true;
		new_challenger.visible = true;
		camera.shake_fade = new_challenger_camera_fade;
		animation_player.setup_new_challenger(new_challenger_ball);


	var t_record:SceneTreeTimer = get_tree().create_timer(obs_delay);
	var t_start_game:SceneTreeTimer = get_tree().create_timer(obs_delay + 0.3);

	t_record.timeout.connect(start_record);

	if(new_challenger_mode):
		var t_new_challenger:SceneTreeTimer = get_tree().create_timer(obs_delay + 1.0);
		t_new_challenger.timeout.connect(start_new_challenger);

	if(tournament_mode):
		var t_tournament:SceneTreeTimer = get_tree().create_timer(obs_delay + 0.3);
		t_tournament.timeout.connect(start_tournament_game);

	if(!patchnote_mode && !new_challenger_mode && !tournament_mode):
		t_start_game.timeout.connect(start_game);

func _physics_process(_delta: float) -> void:
	for fx in just_spawned_fxs:
		fx.emitting = true;
		pass

	just_spawned_fxs.clear();

func _process(delta: float) -> void:
	if(process_timer && time_attack_mode):
		time_attack_elapsed += delta;
		update_time_attack_timer();

func set_earclacks_mode():
	bg.visible = false;
	crt.visible = false;
	author.self_modulate = Color.WEB_GRAY;
	version.self_modulate = Color.WEB_GRAY;
	# arena_bg.color = Color.GHOST_WHITE;

	walltop.material = null;
	walltop.color = Color.BLACK;

	wallbot.material = null;
	wallbot.color = Color.BLACK;

	wallleft.material = null;
	wallleft.color = Color.BLACK;

	wallright.material = null;
	wallright.color = Color.BLACK;

func show_next_patchnote_page():

	if(current_patchnote_page == patchnote_pages.size() - 1):
		end_game();
		return;

	var tween:Tween = create_tween().set_parallel(true);
	tween.tween_property(patchnote_pages[current_patchnote_page], "modulate:a", 0.0, 0.3);
	tween.tween_property(patchnote_pages[current_patchnote_page + 1], "modulate:a", 1.0, 1.3);

	current_patchnote_page += 1;
	patchnote_timer.start();

func start_record():
	if(record):
		obs.send_command("StartRecord");

func stop_record():
	obs.send_command("StopRecord");

func start_game():
	if(!no_announcer):
		AudioManager.play_sfx(ve_announcer, "321GO");

	start_balls();

	if(new_challenger_mode):
		balls[1].stop = true;
		balls[1].freeze = true;

	started = true;

	if(time_attack_mode):
		process_timer = true;

func start_balls():
	var d:Vector2 = Vector2.ONE.rotated(deg_to_rad(randf_range(-50.0,-160.0)));

	if(forced_start_dir != Vector2.ZERO):
		d = forced_start_dir;

	for ball in balls:
		d = d.bounce(Vector2.UP);
		ball.start(self, d);

func end_game():
	var record_elapsed:float = (Time.get_ticks_msec() + (obs_delay * 1000.0)) / 1000.0;
	var time_to_stop:float = max(obs_delay, 80.0 - record_elapsed);

	var winner_team:int = -1;
	var winners:Array[BattleBall];

	for key in teams_alive_members:
		if(teams_alive_members[key] != 0):
			winner_team = key;

		if(bo3_mode):
			teams_alive_members[key] = 1;

	for ball in balls:
		if(ball.team == winner_team):
			winners.push_back(ball);

	if(bo3_mode):
		update_bo3_score(winners[0].get_instance_id(), 1);

		if(bo3_score[winners[0].get_instance_id()] < 2):
			get_tree().create_timer(1).timeout.connect(reset_match);
			return;

	if(!balls[0].is_boss):
		for confetti:MultiFX in confettis.get_children():
			confetti.emit();

	show_winner_text(winners);

	if(process_timer):
		process_timer = false;
		if(balls[0].health > 0): return;
		balls[1].end_game = true;
		balls[2].end_game = true;
		add_time_attack_result();

		print("aled");
		print(time_attack_endgame_delay);

		var t_show_rankings:SceneTreeTimer = get_tree().create_timer(time_attack_endgame_delay);
		t_show_rankings.timeout.connect(show_time_attack_rankings);
	elif(tournament_mode):
		var t_show_tournament_result:SceneTreeTimer = get_tree().create_timer(2.0);
		t_show_tournament_result.timeout.connect(show_tournament_match_result.bind(winner_team));
	else:
		var t_stop_record:SceneTreeTimer = get_tree().create_timer(time_to_stop);
		t_stop_record.timeout.connect(stop_record);

func reset_match():
	balls[0].respawn(_1v1_spots[0], _1v1_hp);
	balls[1].respawn(_1v1_spots[1], _1v1_hp);

	fill_character_ui(balls[0], name_left_1p, sprite_left_1p, details_left_1p, stat_left_1p);
	fill_character_ui(balls[1], name_right_1p, sprite_right_1p, details_right_1p, stat_right_1p);

	balls[0].weapon.reset();
	balls[1].weapon.reset();

	get_tree().create_timer(0.3).timeout.connect(start_balls);

func init_ui():
	winner_text.visible = false;
	time_attack_leaderboard_ui.visible = false;
	bo3_score_ui.visible = bo3_mode;
	damage_dealt_text.original_text = generate_damage_dealt_string();

	fill_character_ui(balls[0], name_left_1p, sprite_left_1p, details_left_1p, stat_left_1p);

	container_1v1_left.visible = balls.size() <= 3;
	container_1v1_right.visible = balls.size() == 2;
	container_2v2_left.visible = balls.size() == 4;
	container_2v2_right.visible = balls.size() >= 3;

	stat_left_1p.visible = container_1v1_left.visible;
	stat_right_1p.visible = container_1v1_right.visible;
	stat_left_1_2p.visible = container_2v2_left.visible;
	stat_left_2_2p.visible = container_2v2_left.visible;
	stat_right_1_2p.visible = container_2v2_right.visible;
	stat_right_2_2p.visible = container_2v2_right.visible;

	if(balls.size() == 2):
		fill_character_ui(balls[1], name_right_1p, sprite_right_1p, details_right_1p, stat_right_1p);
	elif(balls.size() == 3):
		fill_character_ui(balls[1], name_right_1_2p, sprite_right_1_2p, details_right_1_2p, stat_right_1_2p);
		fill_character_ui(balls[2], name_right_2_2p, sprite_right_2_2p, details_right_2_2p, stat_right_2_2p);
	elif(balls.size() == 4):
		fill_character_ui(balls[0], name_left_1_2p, sprite_left_1_2p, details_left_1_2p, stat_left_1_2p);
		fill_character_ui(balls[1], name_left_2_2p, sprite_left_2_2p, details_left_2_2p, stat_left_2_2p);
		fill_character_ui(balls[2], name_right_1_2p, sprite_right_1_2p, details_right_1_2p, stat_right_1_2p);
		fill_character_ui(balls[3], name_right_2_2p, sprite_right_2_2p, details_right_2_2p, stat_right_2_2p);

	time_attack_container.visible = time_attack_mode;
	ta_record.visible = time_attack_mode;
	damage_dealt_container.visible = display_damage_dealt;
	if(time_attack_mode):
		ta_record.format([Utils.convert_time_to_string(time_attack_leaderboards[balls[0].weapon_settings.name.to_upper()].rankings[0].time)]);

func fill_character_ui(ball:BattleBall, name_text:DynamicText, sprite:TextureRect, details_text:DynamicText, stat_text:DynamicText):
	name_text.format([ball.weapon_settings.name]);
	name_text.self_modulate = ball.color;
	sprite.texture = ball.weapon.sprite_2d.texture;
	details_text.format([ball.weapon_settings.details]);
	if(ball.weapon_settings.white_details):
		details_text.text = "[color=" + ball.color.to_html() + "]" + details_text.text + "[/color]";
		details_text.modulate = Color.WHITE;
	else:
		details_text.modulate = ball.color;

	if(details_text.text == ""):details_text.text = " ";

	ball.name_text = name_text;
	ball.ui_sprite = sprite;
	ball.details_text = details_text;
	ball.stat_text = stat_text;

	ball.stat_text.self_modulate = ball.color;
	ball.update_stat_text();

func generate_damage_dealt_string() -> String:
	if(balls.size() == 3):
		return "[color=%s]%s[/color][color=white]※[color=%s]%s[/color]※[color=%s]%s[/color]";

	if(balls.size() == 4):
		if(free_for_all):
			return "[color=%s]%s[/color][color=white]※[color=%s]%s[/color]※[color=%s]%s[/color]※[color=%s]%s[/color]";
		else:
			return "[color=%s]%s[/color][color=white]•[color=%s]%s[/color] ※ [color=%s]%s[/color]•[color=%s]%s[/color]";

	return "";


func on_ball_damaged(id: int, amount:int, from:int):
	if(!balls_ids.has(id)):
		return;

	if(!balls_ids.has(from)):
		return;

	add_damage_dealt(from, abs(amount));

	var fx: GPUParticles2D = fx_hit_prefab.instantiate();
	var ball:BattleBall = get_ball_by_id(id);

	get_tree().current_scene.add_child(fx);
	fx.position = Vector2.ZERO;
	fx.global_position = ball.global_position;
	fx.modulate = ball.color;
	fx.rotation = (ball.global_position - ball.hit_pos).normalized().angle();
	fx.finished.connect(fx.queue_free);
	fx.visible = true;
	just_spawned_fxs.push_back(fx);

	EventBus.camera_trigger_shake.emit( max(hit_shake + amount, 0, hit_max_shake));

	pass ;

func on_ball_clash(id:int, clash_pos:Vector2):
	if(!balls_ids.has(id)):
		return;

	get_ball_by_id(id).set_or_ignore_invincibility(balls[0].clash_invincibility);

	for i in range(5):
		var fx: GPUParticles2D = fx_clash.instantiate();
		var ball:BattleBall = get_ball_by_id(id);
		add_child(fx);
		fx.global_position = clash_pos + Vector2.ONE * randf_range(-15.0, 15.0);
		fx.modulate = ball.color;
		fx.rotation = ball.weapon_slot.global_rotation;
		fx.finished.connect(fx.queue_free);
		just_spawned_fxs.push_back(fx);
		pass ;

func on_ball_dead(id: int):

	if(!balls_ids.has(id)):
		return;

	for ball in balls:
		ball.start_hitstop(0.01,0.6);

	AudioManager.play_sfx(sfx_death, "SFX", 1.0, 0.0, 0.0, true);
	EventBus.camera_trigger_shake.emit(death_shake);

	for i in range(6):
		var fx: GPUParticles2D = fx_death_prefab.instantiate();
		var ball:BattleBall = get_ball_by_id(id);
		add_child(fx);
		fx.global_position = ball.global_position + Vector2.ONE * randf_range(-50.0, 50.0);
		fx.modulate = ball.color;
		just_spawned_fxs.push_back(fx);

	teams_alive_members[get_ball_by_id(id).team] -= 1;
	balls_alive_count -= 1;

	if(free_for_all && balls_alive_count == 1):
		end_game();
		return;

	if(!free_for_all && teams_alive_members[get_ball_by_id(id).team] <= 0):
		end_game();
		return;

	if(balls_alive_count == 2 && !time_attack_mode):
		for ball in balls:
			if(!ball.dead):
				# ball.root.scale = Vector2.ONE * ball.base_root_scale;
				create_tween().tween_property(ball.root, "scale", Vector2.ONE * ball.base_root_scale, 2.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT);
				ball.max_speed += ball.nerfed_speed;
			pass

		animate_label_font(author, 30, 2.4);


func get_ball_by_id(id:int) -> BattleBall:
	if(!balls_ids.has(id)):
		return null;

	return balls[balls_ids[id]];

func sfx_play_bounce(_id:int):
	if(sfx_bounce == null): return;
	var b:BattleBall = get_ball_by_id(_id);
	AudioManager.play_sfx(sfx_bounce if !b.is_boss else sfx_bounce_boss, "SFX");

func start_new_challenger():
	AudioManager.play_sfx(ve_announcer);
	animation_player.play("new_challenger");
	animation_player.animation_finished.connect(new_challenger_over);

func new_challenger_over(_n:StringName):
	new_challenger.visible = false;
	camera.shake_fade = 10.0;
	balls[0].weapon.rotation_speed = balls[0].weapon_settings.base_rotation_speed;
	start_game();


func setup_fight():

	_1v1_spots = [
		arena_center.global_position - Vector2.DOWN * (1080*0.25),
		arena_center.global_position - Vector2.UP * (1080*0.25)
	];

	_1v2_spots = [
		arena_center.global_position + Vector2.LEFT * 250,
		arena_center.global_position + Vector2(250.0, -250.0),
		arena_center.global_position + Vector2(250.0, 250.0)
	];

	_2v2_spots = [
		arena_center.global_position + Vector2(250.0, -250.0),
		arena_center.global_position + Vector2(-250.0, -250.0),
		arena_center.global_position + Vector2(250.0, 250.0),
		arena_center.global_position + Vector2(-250.0, 250.0),
	];

	_4v_ffa_spots = [
		arena_center.global_position + Vector2(350.0, 0.0),
		arena_center.global_position + Vector2(0.0, 350.0),
		arena_center.global_position + Vector2(-350.0, 0.0),
		arena_center.global_position + Vector2(0.0, -350.0)
	];

	balls_alive_count = balls.size();

	if(balls.size() == 4 && !free_for_all):
		balls[0].color = _2v2_colors[0];
		balls[1].color = _2v2_colors[1];
		balls[2].color = _2v2_colors[2];
		balls[3].color = _2v2_colors[3];

	for category in balls_container.get_children():
		for ball:BattleBall in category.get_children():
				ball.ready();
				if(!balls.has(ball)):
					ball.death();
					ball.queue_free();

	if(!new_challenger_mode):
		place_fighting_balls();

func place_fighting_balls():

	if(balls.size() == 1):
		balls[0].global_position = arena_center.global_position;

	elif(balls.size() == 2):
		balls[0].global_position = _1v1_spots[0];
		balls[1].global_position = _1v1_spots[1];

		balls[0].health = _1v1_hp;
		balls[1].health = _1v1_hp;

		balls[0].team = 0
		balls[1].team = 1;

	elif(balls.size() == 3):
		balls[0].global_position = _1v2_spots[0];
		balls[1].global_position = _1v2_spots[1];
		balls[2].global_position = _1v2_spots[2];

		balls[1].health = _1v2_hp;
		balls[2].health = _1v2_hp;

		balls[0].team = 0
		balls[1].team = 1;
		balls[2].team = 1;

		balls[1].max_speed *= 0.7;
		balls[2].max_speed *= 0.7;

		balls[1].gravity_strength *= 0.7;
		balls[2].gravity_strength *= 0.7;

		balls[1].root.scale *= 0.9;
		balls[2].root.scale *= 0.9;

	elif(balls.size() == 4):
		balls[0].global_position = _2v2_spots[0] if !free_for_all else _4v_ffa_spots[0];
		balls[1].global_position = _2v2_spots[1] if !free_for_all else _4v_ffa_spots[1];
		balls[2].global_position = _2v2_spots[2] if !free_for_all else _4v_ffa_spots[2];
		balls[3].global_position = _2v2_spots[3] if !free_for_all else _4v_ffa_spots[3];

		balls[0].health = _1v1_hp;
		balls[1].health = _1v1_hp;
		balls[2].health = _1v1_hp;
		balls[3].health = _1v1_hp;

		balls[0].team = 0;
		balls[1].team = 0 if !free_for_all else 1;
		balls[2].team = 1 if !free_for_all else 2;
		balls[3].team = 1 if !free_for_all else 3;

		balls[0].nerf_max_speed(0.65);
		balls[1].nerf_max_speed(0.65);
		balls[2].nerf_max_speed(0.65);
		balls[3].nerf_max_speed(0.65);

		balls[0].root.scale *= 0.75;
		balls[1].root.scale *= 0.75;
		balls[2].root.scale *= 0.75;
		balls[3].root.scale *= 0.75;

		# Special trick for late game fake zoom
		mult_author_font_size(0.75);

	for ball in balls:
		ball.dead = false;
		ball.visible = true;
		ball.update_health_text();

func update_time_attack_timer():
	ta_timer.text = " " + Utils.convert_time_to_string(time_attack_elapsed) + " ";

func init_damage_dealt(id:int):
	damage_dealt[id] = 0;

func add_damage_dealt(id:int, amount:int):
	damage_dealt[id] += amount;
	update_damage_dealt_UI();

func update_damage_dealt_UI():
	if(!display_damage_dealt):return;

	var args:Array[String];

	for ball in balls:
		args.push_back(ball.color.to_html(false));
		args.push_back(str(damage_dealt[ball.get_instance_id()]));

	damage_dealt_text.format(args);


func add_time_attack_result():
	var boss_name:String = balls[0].weapon_settings.name.to_upper();
	var data:TimeAttackLeaderboard = time_attack_leaderboards[boss_name];
	data.add_line(time_attack_elapsed, [balls[1], balls[2]], [damage_dealt[balls[1].get_instance_id()], damage_dealt[balls[2].get_instance_id()]], boss_name);

	time_attack_leaderboard_ui.update_leaderboard_ui(data);
	time_attack_leaderboard_ui.boss_name_text.format([balls[0].color.to_html(), boss_name]);

func show_time_attack_rankings():
	print("Show");
	time_attack_leaderboard_ui.position.x = 2000.0;
	time_attack_leaderboard_ui.visible = true;
	var tween:Tween = create_tween();
	tween.tween_property(time_attack_leaderboard_ui, "position:x", 0.0, 1.0).set_trans(Tween.TRANS_SPRING);
	var t_stop_record:SceneTreeTimer = get_tree().create_timer(time_attack_ranking_duration);
	t_stop_record.timeout.connect(stop_record);

func set_chromatic_aberration(v: float, d:float):
	var tween: Tween = create_tween();

	tween.parallel().tween_property(chromatic_aberration, "material:shader_parameter/r_displacement", Vector2(v, v), d / 2.0);
	tween.parallel().tween_property(chromatic_aberration, "material:shader_parameter/b_displacement", Vector2(-v, v), d / 2.0);
	tween.parallel().tween_property(chromatic_aberration, "material:shader_parameter/r_displacement", Vector2(0.2, 0.2), d / 2.0).set_delay(d / 2.0);
	tween.parallel().tween_property(chromatic_aberration, "material:shader_parameter/b_displacement", Vector2(-0.2, -0.2), d / 2.0).set_delay(d / 2.0);

func set_time_scale(v: float, d:float):
	var t:Timer = Timer.new();
	t.ignore_time_scale = true;
	t.one_shot = true;;
	t.autostart = true;
	t.wait_time = d;
	t.timeout.connect(func(): Engine.time_scale = 1.0);
	get_tree().current_scene.add_child(t);

	Engine.time_scale = v;

func set_time_scale_smooth(v: float, d:float, burst:float):
	var tween: Tween = get_tree().create_tween();
	tween.custom_step(0.016);
	tween.set_parallel(true);
	tween.tween_property(Engine, "time_scale", v, burst);
	tween.tween_property(Engine, "time_scale", 1.0, d-burst).set_delay(burst);

func show_winner_text(winners:Array[BattleBall]):
	if(winners.size() == 1):
		winner_text.format(["[color=" + winners[0].color.to_html() + "]" + winners[0].weapon_settings.name + "[/color] wins!"]);

	if(winners.size() == 2):
		winner_text.format(
			[
				"[color=" + winners[0].color.to_html() + "]" + winners[0].weapon_settings.name + "[/color] & " + "[color=" + winners[1].color.to_html() + "]" + winners[1].weapon_settings.name + "[/color] win!"
			]
		);

	winner_text.visible = true;

func mult_author_font_size(v:float):
	author.add_theme_font_size_override("normal_font_size", author.get_theme_font_size("normal_font_size") * v);

func animate_label_font(label: RichTextLabel, to: int, duration: float = 0.6):
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(size):
			label.add_theme_font_size_override("normal_font_size", size),
		author.get_theme_font_size("normal_font_size"),
		to,
		duration
	)

func init_bo3_score():
	for ball in balls:
		bo3_score[ball.get_instance_id()] = 0;

	if(preset_score != Vector2i.ZERO):
		bo3_score[bo3_score.keys()[0]] = preset_score.x;
		bo3_score[bo3_score.keys()[1]] = preset_score.y;

	update_bo3_score(balls[0].get_instance_id(), 0);

func update_bo3_score(id:int, points:int):
	bo3_score[id] += points;

	var args:Array[String] = [];

	for ball_id in bo3_score.keys():
		args.push_back(get_ball_by_id(ball_id).color.to_html());
		args.push_back(str(bo3_score[ball_id]));

	bo3_score_ui.format(args);

func start_tournament_game():
	AudioManager.play_sfx(ve_announcer, "321GO");

	var t_tournament:SceneTreeTimer = get_tree().create_timer(4.0);
	t_tournament.timeout.connect(start_game);

	bracket.load_tournament();
	get_tree().create_timer(0.3).timeout.connect(func():bracket.toggle_next_match());

	var tween:Tween = create_tween();
	tween.tween_property(tournament_container, "global_position", Vector2.RIGHT * 2000.0, 1.0).set_delay(1.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK);
	tween.tween_property(tournament_container, "visible", false, 0.0);

func show_tournament_match_result(w:int):
	var tween:Tween = create_tween();
	tween.tween_property(tournament_container, "visible", true, 0.0);
	tween.tween_property(tournament_container, "global_position", Vector2.ZERO, 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK);
	tween.tween_callback(bracket.set_match_winner.bind(bracket.get_match_local_id(w))).set_delay(1.0);
	tween.tween_callback(bracket.save_tournament);

	var t_stop_record:SceneTreeTimer = get_tree().create_timer(8.0);
	t_stop_record.timeout.connect(stop_record);
