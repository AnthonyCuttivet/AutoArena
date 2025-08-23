@tool
class_name TimeAttackLeaderboard extends Resource

@export_tool_button("Sort") var tool_sort_action = tool_sort;

@export var rankings: Array[TimeAttackData];

func add_line(time:float, balls:Array[BattleBall], damage:Array[int], boss_name:String):
	var l:TimeAttackData = TimeAttackData.new();

	l.boss = boss_name;

	l.time = time;

	var b0:BattleBall = balls[0];
	var b1:BattleBall = balls[1];

	l.ball_1_color = b0.color;
	l.ball_1_name = b0.name;
	l.ball_1_sprite = b0.weapon.sprite_2d.texture;
	l.ball_1_flip_h = b0.weapon.sprite_2d.flip_h;
	l.ball_1_rot = b0.weapon.sprite_2d.rotation;
	l.ball_1_offset = (b0.weapon_settings.offset) + b0.weapon_settings.base_size;
	l.ball_1_damage = damage[0];

	l.ball_2_color = b1.color;
	l.ball_2_name = b1.name;
	l.ball_2_sprite = b1.weapon.sprite_2d.texture;
	l.ball_2_flip_h = b1.weapon.sprite_2d.flip_h;
	l.ball_2_rot = b1.weapon.sprite_2d.rotation;
	l.ball_2_offset = (b1.weapon_settings.offset) + b1.weapon_settings.base_size;
	l.ball_2_damage = damage[1];

	rankings.push_back(l);
	rankings.sort_custom(sort_rankings);

	if(rankings.size() < 8):
		save_res(l);
	else:
		rankings.remove_at(7);

func sort_rankings(a:TimeAttackData,b:TimeAttackData):
	return a.time < b.time;

func save_res(l: TimeAttackData):
	# Make sure the directory exists
	var dir_path = "res://Resources/Leaderboards/TMP_RANKS"
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	# Use safe filename (replace ':' to avoid Windows errors)
	var timestamp = Time.get_time_string_from_system().replace(":", "-")
	var save_path = dir_path + "/TA_" + l.boss + "_" + timestamp + ".tres"

	var error = ResourceSaver.save(l, save_path)

	if error == OK:
		print("Resource saved successfully at:", save_path)
	else:
		push_error("Failed to save resource: %s" % error)

func tool_sort():
	rankings.sort_custom(sort_rankings);
	print("Sorted " + self.resource_path);
