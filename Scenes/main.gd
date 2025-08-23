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
@export var non_boss_scale:float = 0.11;
@export var non_boss_weapon_scale:float = 18.0;
@export var attraction_point:Node2D;

@onready var name_boss_1: DynamicText = $UI/Top/Boss/WeaponLeft/Name
@onready var sprite_boss_1: TextureRect = $UI/Top/Boss/WeaponLeft/Sprite
@onready var boss_details_1: DynamicText = $UI/Top/Boss/BossDetails
@onready var stat_left: DynamicText = $UI/Bottom/StatLeft

@onready var name_1: DynamicText = $UI/Top/WeaponRight/WeaponAlly/Name
@onready var sprite_1: TextureRect = $UI/Top/WeaponRight/WeaponAlly/Sprite
@onready var stat_ally_1: DynamicText = $UI/Bottom/StatAlly
@onready var weapon_details_1: DynamicText = $UI/Top/WeaponRight/WeaponDetails

@onready var name_2: DynamicText = $UI/Top/WeaponRight/WeaponAlly2/Name
@onready var sprite_2: TextureRect = $UI/Top/WeaponRight/WeaponAlly2/Sprite
@onready var stat_ally_2: DynamicText = $UI/Bottom/StatAlly2
@onready var weapon_details_2: DynamicText = $UI/Top/WeaponRight/WeaponDetails2

@onready var weapon_right: VBoxContainer = $UI/Top/WeaponRight
@onready var boss_2: VBoxContainer = $UI/Top/Boss2
@onready var sprite_boss_2: TextureRect = $UI/Top/Boss2/WeaponRight/Sprite
@onready var name_boss_2: DynamicText = $UI/Top/Boss2/WeaponRight/Name
@onready var boss_details_2: DynamicText = $UI/Top/Boss2/BossDetails
@onready var stat_right: DynamicText = $UI/Bottom/StatRight

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

@onready var special_effects_parent: Node2D = $SpecialEffectsParent
@onready var projectiles_bg_parent: Node2D = $ProjectilesBGParent

@onready var confettis: Node2D = $Confettis
@onready var chromatic_aberration: ColorRect = $ChromaticAberration

var balls_ids: Dictionary[int, int];
var teams_alive_members: Dictionary[int, int];

var current_patchnote_page:int = 0;
var patchnote_timer:Timer = null;

var _1v1_spots:Array[Vector2];
var _1v2_spots:Array[Vector2];

var just_spawned_fxs:Array[GPUParticles2D];

var time_attack_elapsed:float = 0.0;

var started:bool = false;
var process_timer:bool = false;

var damage_dealt:Dictionary[int,int];

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

	if(time_attack_mode):
		display_damage_dealt = true;

	init_ui();

	teams_alive_members[0] = 0;
	teams_alive_members[1] = 0;

	setup_fight();

	for i in range(balls.size()):
		balls_ids[balls[i].get_instance_id()] = i;
		teams_alive_members[balls[i].team] += 1;
		# balls[i].weapon_slot.global_rotation_degrees = randf_range(0.0,360.0);
		balls[i].weapon_slot.global_rotation_degrees = 0.0;
		if(i==0 && balls.size() > 1):
			balls[0].target = balls[1];
		else:
			balls[i].target = balls[0];

		init_damage_dealt(balls[i].get_instance_id());

	if(display_damage_dealt):
		update_damage_dealt_UI();

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

	if(!patchnote_mode && !new_challenger_mode):
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
		AudioManager.play_sfx(ve_announcer, "Master");

	var d:Vector2 = Vector2.ONE.rotated(deg_to_rad(randf_range(-50.0,-160.0)));

	if(forced_start_dir != Vector2.ZERO):
		d = forced_start_dir;

	for ball in balls:
		d = d.bounce(Vector2.UP);
		ball.start(self, d);

	if(new_challenger_mode):
		balls[1].stop = true;
		balls[1].freeze = true;

	started = true;

	if(time_attack_mode):
		process_timer = true;

func end_game():

	var record_elapsed:float = (Time.get_ticks_msec() + (obs_delay * 1000.0)) / 1000.0;
	var time_to_stop:float = max(obs_delay, 80.0 - record_elapsed);

	if(!balls[0].is_boss):
		for confetti:MultiFX in confettis.get_children():
			confetti.emit();

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
	else:
		var t_stop_record:SceneTreeTimer = get_tree().create_timer(time_to_stop);
		t_stop_record.timeout.connect(stop_record);


func init_ui():
	time_attack_leaderboard_ui.visible = false;

	name_boss_1.format([balls[0].weapon_settings.name]);
	name_boss_1.self_modulate = balls[0].color;
	sprite_boss_1.texture = balls[0].weapon.sprite_2d.texture;
	boss_details_1.format([balls[0].weapon_settings.details]);
	boss_details_1.modulate = balls[0].color;
	if(boss_details_1.text == ""):boss_details_1.text = " ";

	balls[0].stat_text = stat_left;
	balls[0].stat_text.self_modulate = balls[0].color;
	balls[0].update_stat_text();

	if(balls.size() == 2):
		weapon_right.visible = false;
		boss_2.visible = true;
		stat_right.visible = true;
		stat_ally_1.visible = false;
		stat_ally_2.visible = false;

		name_boss_2.format([balls[1].weapon_settings.name]);
		name_boss_2.self_modulate = balls[1].color;
		sprite_boss_2.texture = balls[1].weapon.sprite_2d.texture;
		boss_details_2.format([balls[1].weapon_settings.details]);
		boss_details_2.modulate = balls[1].color;
		if(boss_details_2.text == ""):boss_details_2.text = " ";

		balls[1].stat_text = stat_right;
		balls[1].stat_text.self_modulate = balls[1].color;
		balls[1].update_stat_text();

	elif(balls.size() == 3):
		boss_2.visible = false;
		stat_right.visible = false;

		name_1.format([balls[1].weapon_settings.name]);
		name_1.self_modulate = balls[1].color;
		sprite_1.texture = balls[1].weapon.sprite_2d.texture;
		weapon_details_1.text = balls[1].weapon_settings.details;
		weapon_details_1.modulate = balls[1].color;
		if(weapon_details_1.text == ""):weapon_details_1.text = " ";

		name_2.format([balls[2].weapon_settings.name]);
		name_2.self_modulate = balls[2].color;
		sprite_2.texture = balls[2].weapon.sprite_2d.texture;
		weapon_details_2.text = balls[2].weapon_settings.details;
		weapon_details_2.modulate = balls[2].color;
		if(weapon_details_2.text == ""):weapon_details_2.text = " ";


		balls[1].stat_text = stat_ally_1;
		balls[2].stat_text = stat_ally_2;

		balls[1].stat_text.self_modulate = balls[1].color;
		balls[2].stat_text.self_modulate = balls[2].color;

		balls[1].update_stat_text();
		balls[2].update_stat_text();

	time_attack_container.visible = time_attack_mode;
	ta_record.visible = time_attack_mode;
	damage_dealt_container.visible = display_damage_dealt;
	if(time_attack_mode):
		ta_record.format([Utils.convert_time_to_string(time_attack_leaderboards[balls[0].weapon_settings.name.to_upper()].rankings[0].time)]);

func set_weapon_ui_sprite(id:int, color:Color = Color.WHITE):
	var ball:BattleBall = get_ball_by_id(id);
	var local_id:int = balls_ids[id];

	var tx:TextureRect = null;

	if(balls.size() == 1):
		tx = sprite_boss_1;
	if(balls.size() == 2):
		tx = sprite_boss_1 if local_id == 0 else sprite_boss_2;
	else:
		if(local_id == 0):
			tx = sprite_boss_1;
		else:
			tx = sprite_1 if local_id == 1 else sprite_2;

	tx.texture = ball.weapon.sprite_2d.texture;
	tx.self_modulate = color;

func set_weapon_ui_name(id:int, color:Color, t:String = ""):
	var ball:BattleBall = get_ball_by_id(id);
	var local_id:int = balls_ids[id];

	var text:DynamicText = null;

	if(balls.size() == 1):
		text = name_boss_1;
	elif(balls.size() == 2):
		text = name_boss_1 if local_id == 0 else name_boss_2;
	else:
		if(local_id == 0):
			text = name_boss_1;
		else:
			text = name_1 if local_id == 1 else name_2;

	if(t == ""):
		text.format([ball.weapon_settings.name]);
	else:
		text.text = t;

	text.self_modulate = color;

func set_weapon_ui_stat(id:int, color:Color):
	var ball:BattleBall = get_ball_by_id(id);
	var local_id:int = balls_ids[id];

	var text:DynamicText = null;

	if(balls.size() == 1):
		text = stat_left;
	elif(balls.size() == 2):
		text = stat_left if local_id == 0 else stat_right;
	else:
		if(local_id == 0):
			text = stat_left;
		else:
			text = stat_ally_1 if local_id == 1 else stat_ally_2;

	text.format([ball.weapon_settings.name]);

	text.self_modulate = color;

func set_weapon_ui_details(id:int, color:Color, raw:bool = false):
	var ball:BattleBall = get_ball_by_id(id);
	var local_id:int = balls_ids[id];

	var text:DynamicText = null;

	if(balls.size() == 1):
		text = boss_details_1;
	elif(balls.size() == 2):
		text = boss_details_1 if local_id == 0 else boss_details_2;
	else:
		if(local_id == 0):
			text = boss_details_1;
		else:
			text = weapon_details_1 if local_id == 1 else weapon_details_2;

	if(!raw):
		text.format([ball.weapon_settings.details]);
	else:
		text.text = ball.weapon_settings.details;

	text.modulate = color;


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

func on_ball_clash(id:int):
	if(!balls_ids.has(id)):
		return;

	get_ball_by_id(id).add_invincibility(balls[0].clash_invincibility);

	for i in range(5):
		var fx: GPUParticles2D = fx_clash.instantiate();
		var ball:BattleBall = get_ball_by_id(id);
		add_child(fx);
		fx.global_position = ball.weapon.sprite_2d.global_position + Vector2.ONE * randf_range(-15.0, 15.0);
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

	if(teams_alive_members[get_ball_by_id(id).team] <= 0):
		end_game();
		return;

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
	_1v1_spots = [arena_center.global_position - Vector2.DOWN * (1080*0.25), arena_center.global_position - Vector2.UP * (1080*0.25)];
	_1v2_spots = [arena_center.global_position + Vector2.LEFT * 250, arena_center.global_position + Vector2(250.0, -250.0), arena_center.global_position + Vector2(250.0, 250.0)];

	var i:int = 0;
	for category in balls_container.get_children():
		for ball:BattleBall in category.get_children():
				if(!balls.has(ball)):
					ball.death();
					ball.queue_free();
					i += 1;

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

		#Halve gravity against bosses
		balls[1].gravity_strength *= 0.25;
		balls[2].gravity_strength *= 0.25;

		# balls[1].max_speed *= 0.75;
		# balls[2].max_speed *= 0.75;

		balls[1].root.scale *= 0.75;
		balls[2].root.scale *= 0.75;

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

	damage_dealt_text.format(
		[
			balls[0].color.to_html(false), str(damage_dealt[balls[0].get_instance_id()]),
			balls[1].color.to_html(false), str(damage_dealt[balls[1].get_instance_id()]),
			balls[2].color.to_html(false), str(damage_dealt[balls[2].get_instance_id()]),
		]
	);

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
