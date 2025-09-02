@tool
class_name TournamentBracket extends Node2D

@export_tool_button("Generate") var gen = generate_bracket;
@export_tool_button("NextMatch") var nextmatch = toggle_next_match;
@export_tool_button("SetWinner") var setwinner = toggle_winner;
@export_tool_button("Save") var save = save_tournament;
@export_tool_button("Load") var load = load_tournament;
@export_tool_button("Clear") var clear = clear_bracket;

@export var scene_root:Node2D;
@export var tournament_data:TournamentData;
@export var balls:Dictionary[String, WeaponSettings];
@export var setup_slide_sfx:SFX;
@export var win_sfx:SFX;

# --- Customization
@export var line_width:int = 4;
@export var match_length:float = 100.0;
@export var match_height:float = 50.0;
@export var trophy_sprite:Texture;
@export var sprite_scale:float = 1.0;
@export var tween_duration:float = 0.5;

var max_depth:int = 0;
var sprites:Array[Sprite2D];
var starting_positions:Array[Vector2];
var next_match:int = 0;
var matches:Array[TournamentBracketMatch] = [];
var match_id:int = 0;
var winner_next_match = 0;
var next_match_players_set:int = 0;
var trophy_sprite2D:Sprite2D = null;

func generate_bracket():

	var current_depth:int = 1;
	max_depth = (tournament_data.players.size() / 2) - 1;
	winner_next_match = tournament_data.players.size() / 2;

	starting_positions = [];

	if(max_depth == 1):
		var step:int = current_depth * 2;
		for j in range(0, tournament_data.players.size(), step):
			generate_match(floor(j/(step*2)), 1 if j % (step*2) == 0 else -1, current_depth, [j, j+1]);
		generate_finals(0, true);
	else:
		for i in max_depth:
			if(i == max_depth-1):
				generate_finals(i);
			else:
				var step:int = current_depth * 2;
				for j in range(0, tournament_data.players.size(), step):
					generate_match(floor(j/(step*2)), 1 if j % (step*2) == 0 else -1, current_depth, [j, j+1]);

			current_depth += 1;

	for i in tournament_data.players.size():
		sprites.push_back(create_sprite(get_player(tournament_data.players[i]).spr, starting_positions[i], "Player1"));

	var trophy_pos:Vector2 = Vector2.ZERO;

	if(max_depth == 1):
		trophy_pos = Vector2(match_length * (max_depth + 1), match_height / 2.0);
	else:
		trophy_pos = global_position + Vector2(match_length, match_height / 2.0) * max_depth;

	trophy_sprite2D = create_sprite(trophy_sprite, trophy_pos, "SpriteTrophy", true);

func clear_bracket():
	for child in self.get_children():
		child.queue_free();

	max_depth = 0;
	sprites.clear();
	starting_positions.clear();
	next_match = 0;
	matches.clear();
	match_id = 0;

func toggle_next_match():
	if(next_match == tournament_data.players.size() - 2):
		setup_finals(matches[next_match]);
	else:
		setup_match(matches[next_match]);
	pass;

func toggle_winner():
	var m:TournamentBracketMatch = matches[next_match];
	set_match_winner(m.match_data.players[randi_range(0,1)]);

func generate_match(line:int, side:int, depth:int, p:Array[int]):
	# print(str(line) + " // " + str(side) + " // " + str(depth));
	var pos_x:float = 0.0 if side == 1 else match_length * (3 + max_depth);
	var pos_y:float = line * match_height * 2 * depth;

	pos_x += match_length * (depth - 1) * side;
	pos_y += (match_height / 2.0) * (depth - 1);

	var root:Node2D = create_container(Vector2(pos_x, pos_y), "Match1");

	draw_match(match_length, match_height * depth, side, root, depth == 1);

	if(depth == 1):
		matches.back().match_data.set_players(p);

	matches.back().match_data.m_id = match_id;
	match_id += 1;

func generate_finals(depth:int, f:bool = false):
	var tbmatch:TournamentBracketMatch = TournamentBracketMatch.new();
	var pos_x:float = match_length * depth;
	var pos_y:float = (match_height / 2.0) * (depth + 1);

	if(f): pos_x = match_length * (depth + 1);

	var root:Node2D = create_container(Vector2(pos_x, pos_y), "Finals");
	tbmatch.container = root;
	tbmatch.p1_match_line = draw_sline(Vector2.ZERO, match_length / 2.0, Vector2.RIGHT, root);
	tbmatch.p2_match_line = draw_sline(Vector2(match_length*2, 0.0), match_length / 2.0, Vector2.LEFT, root);
	tbmatch.p1_win_line = draw_sline(Vector2.RIGHT * (match_length / 2.0), match_length / 2.0, Vector2.RIGHT, root);
	tbmatch.p2_win_line = draw_sline(Vector2((match_length / 2.0) * 3, 0.0), match_length / 2.0, Vector2.LEFT, root);
	tbmatch.match_data.is_finals = true;
	tbmatch.match_data.m_id = match_id;
	matches.push_back(tbmatch);


func create_container(pos:Vector2, n:String) -> Node2D:
	var container:Node2D = Node2D.new();
	self.add_child(container);

	container.position = pos;

	container.name = n;
	container.owner = scene_root;

	return container;

func draw_sline(pos:Vector2, length:float, dir:Vector2, parent:Node2D, c:Color = Color.BLACK) -> Line2D:
	var line:Line2D = Line2D.new();

	parent.add_child(line);

	line.position = pos;
	line.default_color = c;
	line.width = line_width;
	line.add_point(Vector2.ZERO);
	line.add_point(length * dir);
	line.begin_cap_mode = Line2D.LINE_CAP_BOX;
	line.end_cap_mode = Line2D.LINE_CAP_BOX;

	line.name = "Line";
	line.owner = scene_root;

	return line;

func draw_match(length:float, height:float, side:int, root:Node2D, starting_pos:bool = false):
	var tbmatch:TournamentBracketMatch = TournamentBracketMatch.new();

	tbmatch.container = root;

	tbmatch.p1_match_line = draw_sline(Vector2.ZERO, length, Vector2.RIGHT * side, root);
	tbmatch.p2_match_line = draw_sline(Vector2(0.0, height), length, Vector2.RIGHT * side, root);
	tbmatch.p1_win_line = draw_sline(Vector2(length * side, 0.0), height / 2.0, Vector2.DOWN, root);
	tbmatch.p2_win_line = draw_sline(Vector2(length * side, height), height / 2.0, Vector2.UP, root);

	tbmatch.match_data.winner_next_match = winner_next_match;
	next_match_players_set += 1;
	if(next_match_players_set % 2 == 0):
		winner_next_match += 1;
		next_match_players_set = 0;

	if(starting_pos):
		starting_positions.push_back(tbmatch.p1_match_line.global_position);
		starting_positions.push_back(tbmatch.p2_match_line.global_position);

	matches.push_back(tbmatch);

func create_sprite(tx:Texture, pos:Vector2, n:String, local:bool = false) -> Node2D:
	var spr:Sprite2D = Sprite2D.new();
	self.add_child(spr);

	if(local):
		spr.position = pos;
	else:
		spr.position = Vector2.ZERO;
		spr.global_position = pos;

	spr.texture = tx;
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;
	spr.scale = Vector2.ONE * sprite_scale;
	spr.name = n;
	spr.owner = scene_root;

	return spr;

func setup_match(m:TournamentBracketMatch):
	var t:Tween = create_tween();
	t.set_parallel(true);
	t.tween_property(sprites[m.match_data.players[0]], "global_position", m.p1_match_line.to_global(m.p1_match_line.points[1]), tween_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK);
	t.tween_property(sprites[m.match_data.players[1]], "global_position", m.p2_match_line.to_global(m.p2_match_line.points[1]), tween_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK);

	AudioManager.play_sfx(setup_slide_sfx);
	AudioManager.play_sfx(setup_slide_sfx);

	pass;

func setup_finals(m:TournamentBracketMatch):
	var t:Tween = create_tween();
	t.set_parallel(true);
	t.tween_property(sprites[m.match_data.players[0]], "global_position", m.p1_match_line.to_global(m.p1_match_line.points[1]), tween_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK);
	t.tween_property(sprites[m.match_data.players[1]], "global_position", m.p2_match_line.to_global(m.p2_match_line.points[1]), tween_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK);
	t.tween_property(trophy_sprite2D, "global_position", trophy_sprite2D.global_position + Vector2.RIGHT * 100.0, tween_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK);

	AudioManager.play_sfx(setup_slide_sfx);
	AudioManager.play_sfx(setup_slide_sfx);

	print("Finals players : " + str(m.match_data.players[0]) + " vs " + str(m.match_data.players[1]));

	pass;

func set_match_winner(w:int):
	var m:TournamentBracketMatch = matches[next_match];
	next_match += 1;
	m.match_data.winner = w;
	matches[m.match_data.winner_next_match].match_data.players.push_back(w);
	print("// Match " + str(m.match_data.m_id) + " winner : " + str(w));

	var p1_winner:bool = m.match_data.players[0] == w;
	var l_sprite:Sprite2D = sprites[m.match_data.players[1] if p1_winner else m.match_data.players[0]];
	var l_match:Line2D = m.p2_match_line if p1_winner else m.p1_match_line;
	var l_win:Line2D = m.p2_win_line if p1_winner else m.p1_win_line;
	var d:float = tween_duration / 2.0;

	var t:Tween = create_tween();
	t.set_parallel(true);
	t.tween_property(sprites[w], "global_position", m.p1_win_line.to_global(m.p1_win_line.points[1]), d).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK);
	t.tween_property(l_sprite, "scale", Vector2.ONE * (sprite_scale / 2.0), d).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK);
	t.tween_property(l_match, "default_color", Color.GRAY, d).set_ease(Tween.EASE_OUT);
	t.tween_property(l_win, "default_color", Color.GRAY, d).set_ease(Tween.EASE_OUT);

	AudioManager.play_sfx(win_sfx);


func get_player(s:String) -> WeaponSettings:
	return balls[s];

func save_tournament():
	save_res();

func load_tournament():
	clear_bracket();
	generate_bracket();

	for i in matches.size():
		var m:TournamentBracketMatch = matches[i];
		m.match_data = tournament_data.matches[i];
		if(m.match_data.winner != -1):
			set_match_winner(m.match_data.winner);
		pass

	print("After load next match " + str(next_match));

func get_match_local_id(team:int) -> int:
	return matches[next_match].match_data.players[team];

func save_res():
	# Make sure the directory exists
	var dir_path = "res://Resources/Tournaments/"
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	# Use safe filename (replace ':' to avoid Windows errors)
	var timestamp = Time.get_time_string_from_system().replace(":", "-")
	var save_path = dir_path + "/Tournament_" + tournament_data.tournament_name + "_" + timestamp + ".tres"

	tournament_data.next_match = next_match;
	var matches_data:Array[TournamentMatchData] = [];

	for m in matches:
		matches_data.push_back(m.match_data);
		pass

	tournament_data.matches = matches_data;

	var error = ResourceSaver.save(tournament_data, save_path)

	if error == OK:
		print("Resource saved successfully at:", save_path)
	else:
		push_error("Failed to save resource: %s" % error)
