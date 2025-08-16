class_name RankingLine extends MarginContainer

@onready var rank_text: DynamicText = $MainContainer/RankText
@onready var time_text: DynamicText = $MainContainer/TimeText
@onready var team_text: DynamicText = $MainContainer/TeamText
@onready var scores_text: DynamicText = $MainContainer/ScoresText

func fill_data(data:TimeAttackData, rank:int):
	rank_text.text = str(rank);
	time_text.text = Utils.convert_time_to_string(data.time);
	team_text.format(
		[
			data.ball_1_color.to_html(), str(data.ball_1_name),
			data.ball_2_color.to_html(), str(data.ball_2_name)
		]
	);
	scores_text.format(
		[
			data.ball_1_color.to_html(), str(data.ball_1_damage),
			data.ball_2_color.to_html(), str(data.ball_2_damage)
		]
	);
	
	
