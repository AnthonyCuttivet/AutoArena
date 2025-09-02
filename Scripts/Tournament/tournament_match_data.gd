class_name TournamentMatchData extends Resource

@export var m_id:int;
@export var is_finals:bool = false;
@export var players:Array[int];
@export var winner:int = -1;
@export var winner_next_match:int = -1;

func set_players(p:Array[int]):
    players = p;
