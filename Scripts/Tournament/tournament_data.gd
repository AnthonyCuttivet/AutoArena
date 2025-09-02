class_name TournamentData extends Resource

@export var tournament_name:String;
@export var players: Array[String];
@export var matches: Array[TournamentMatchData] = [];
@export var next_match:int = 0;


