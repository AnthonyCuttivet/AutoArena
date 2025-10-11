class_name HydraTournamentTeamLine extends Control

@onready var team_name: DynamicText = $RankingLine/MainContainer/TeamName
@onready var team_members: DynamicText = $RankingLine/MainContainer/TeamMembers
@onready var sprite_1: TextureRect = $RankingLine/MainContainer/TeamSprites/Sprite1
@onready var sprite_2: TextureRect = $RankingLine/MainContainer/TeamSprites/Sprite2

var p:HydraTournamentSelector = null;

func fill_line(name:String, c:Color, p1:WeaponSettings, p2:WeaponSettings, delay:float):
	team_name.format([Color.WHITE.to_html(), c.to_html(), name]);
	team_members.format([p1.color.to_html(), p1.name, p2.color.to_html(), p2.name]);
	sprite_1.texture = p1.spr;
	sprite_2.texture = p2.spr;
	
	position.x = -2000.0;
	tween_line(delay);

func tween_line(delay:float):
	var t:Tween = create_tween();
	t.tween_property(self, "position:x", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(delay);
