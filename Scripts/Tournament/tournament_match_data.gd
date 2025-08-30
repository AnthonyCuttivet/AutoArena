class_name TournamentMatchData extends Resource

var m_id:int;
var is_finals:bool = false;
var players:Array[int];
var winner:int;

func set_players(p:Array[int]):
    players = p;

func set_winner(w:int):
    winner = w;
