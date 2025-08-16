class_name AddComboBumper extends Bumper

@export var add_combo_value: int = 1;

var text: String = "NULL";

func apply_on_bump_effect(ball: Ball):
	if (Utils.get_other_ball(ball).health <= 0): return ;

	var combo_added: int = ball.add_combo(add_combo_value);
	# text = ("+" if combo_added > 0.0 else "") + str(combo_added);
	# Utils.spawn_text_indicator(self.get_tree().root, text, ball.global_position, bg.self_modulate);
	pass ;
