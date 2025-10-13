class_name TimeAttackLeaderboardUI extends Control

@export var crowns:Array[Texture];
@export var podium_colors:Array[Color];
@export var podium_freqs:Array[int];

var leaderboard_data: TimeAttackLeaderboard;

@onready var boss_name_text: DynamicText = $TitleContainer/BossNameText
@onready var podium_1: PodiumSlot = $Podium1
@onready var podium_2: PodiumSlot = $Podium2
@onready var podium_3: PodiumSlot = $Podium3
@onready var ranks: VBoxContainer = $Ranks

func update_leaderboard_ui(data:TimeAttackLeaderboard):
	leaderboard_data = data;

	podium_2.visible = leaderboard_data.rankings.size() >= 2;
	podium_3.visible = leaderboard_data.rankings.size() >= 3;

	podium_2.crown.texture = crowns[1];
	podium_3.crown.texture = crowns[2];

	for i in ranks.get_child_count():
		ranks.get_child(i).visible = leaderboard_data.rankings.size() >= i + 4;

	for i in leaderboard_data.rankings.size():
		if(i >= 7): continue;
		if(i == 0): podium_1.fill_data(leaderboard_data.rankings[i], podium_colors[i].to_html(), str(podium_freqs[i])); continue;
		if(i == 1): podium_2.fill_data(leaderboard_data.rankings[i], podium_colors[i].to_html(), str(podium_freqs[i])); continue;
		if(i == 2): podium_3.fill_data(leaderboard_data.rankings[i], podium_colors[i].to_html(), str(podium_freqs[i])); continue;

		ranks.get_child(i-3).fill_data(leaderboard_data.rankings[i], i+1);
		pass;
