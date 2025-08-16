class_name DynamicText extends RichTextLabel

var original_text:String = "NULL";

func _ready() -> void:
	original_text = text;

func format(v:Array[String]):
	text = original_text % v;

func bump(s:float, d:float):
	var tween:Tween = get_tree().create_tween();
	tween.tween_property(self, "scale", Vector2(s, s), d).set_ease(Tween.EASE_IN);
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), d).set_delay(d).set_ease(Tween.EASE_OUT);
