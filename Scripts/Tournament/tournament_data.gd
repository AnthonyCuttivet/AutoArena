class_name TournamentData extends Resource

@export var contestants: Array[String] = [] # Names or IDs
@export var rounds: Array = [] # Each round is an Array of matches

# Match format: { "player1": idx, "player2": idx, "winner": -1 }
