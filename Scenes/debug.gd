class_name Debug extends Control

@onready var values_1: Label = $Ball1/Values
@onready var values_2: Label = $Ball2/Values
@onready var game_manager: Node = $"../GameManager"

@export var values: Array[Label];

func _process(delta: float) -> void:
	if (!game_manager.init): return ;

	for i in game_manager.balls.size():
		if (game_manager.balls[i] == null): continue ;
		values[i].text = get_debug_str(game_manager.balls[i]);


func get_debug_str(ball: Ball) -> String:
	return "Frozen " + str(ball.freeze) + "\n" + "Health " + str(snapped(ball.health, 0.01)) + "/" + str(ball.settings.max_health) + "\n" + "Low Health : " + str(ball.is_low_health()) + "\n" + "Invincible ? " + str(ball.is_invincible) + "\n" + "Speed " + str(snapped(ball.get_speed(), 0.01)) + "/" + str(ball.get_current_max_speed()) + "\n" + "Combo " + str(ball.combo);
