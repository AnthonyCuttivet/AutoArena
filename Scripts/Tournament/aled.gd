@tool
class_name Aled extends Node2D

@export_tool_button("Generate") var gen = generate_bracket;
@export_tool_button("Clear") var clear = clear_bracket;

@export var scene_root:Node2D;
@export var players:Array[String];

# --- Customization
@export var line_width:int = 4;
@export var match_length:float = 100.0;
@export var match_height:float = 50.0;

var max_depth:int = 0;

func generate_bracket():

	var current_depth:int = 1;
	max_depth = (players.size() / 2) - 1;

	print("-----");

	for i in max_depth:
		if(i == max_depth-1):
			return;

		var step:int = current_depth * 2;
		for j in range(0, players.size(), step):
			generate_match(floor(j/(step*2)), 1 if j % int(players.size() / current_depth) == 0 else -1, current_depth, [j, j+1]);

		current_depth += 1;



	# for i in range(0, players.size(), 2):
	# 	generate_match(floor(i/4.0), 1 if i % int(players.size() / 2.0) == 0 else -1, 1, [i, i+1]);


	# for i in range(0, players.size(), 4):
	# 	generate_match(floor(i/8.0), 1 if i % int(players.size() / 1.0) == 0 else -1, 2, []);

	pass;

func clear_bracket():
	for child in self.get_children():
		child.queue_free();


func generate_match(line:int, side:int, depth:int, p:Array[int]):
	print(str(line) + " // " + str(side) + " // " + str(depth));
	var pos_x:float = 0.0 if side == 1 else match_length * (2 + max_depth);
	var pos_y:float = line * match_height * 2 * depth;

	pos_x += match_length * (depth - 1) * side;
	pos_y += (match_height / 2.0) * (depth - 1);

	var root:Node2D = create_container(Vector2(pos_x, pos_y), "Match1");

	draw_match(match_length, match_height * depth, side, root);

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

func draw_match(length:float, height:float, side:int, root:Node2D):
	draw_sline(Vector2.ZERO, length, Vector2.RIGHT * side, root);
	draw_sline(Vector2(0.0, height), length, Vector2.RIGHT * side, root);
	draw_sline(Vector2(length * side, 0.0), height / 2.0, Vector2.DOWN, root);
	draw_sline(Vector2(length * side, height), height / 2.0, Vector2.UP, root);
