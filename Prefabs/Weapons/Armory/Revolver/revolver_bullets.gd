class_name RevolverBullets extends Control

@onready var container: HBoxContainer = $HBoxContainer

func consume_bullet(slot:int):
	container.get_child(slot).modulate.a = 0.2;

func reload_bullet(slot:int, tx:Texture2D):
	container.get_child(slot).get_child(0).texture = tx;
	container.get_child(slot).modulate.a = 1.0;

	var t:Tween = create_tween();
	t.tween_property(container.get_child(slot), "position:y", -20.0, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);
	t.tween_property(container.get_child(slot), "position:y", 0.0, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);
