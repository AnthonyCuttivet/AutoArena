class_name BonesEye extends Node2D

@export var eye_yellow:Color;
@export var sprite:Sprite2D;
@export var blink_duration:float;

func activate(s:bool):
	self.visible = s;
	if(s):
		var t:Tween = create_tween();
		t.tween_property(sprite, "self_modulate", eye_yellow, blink_duration);
		t.tween_property(sprite, "self_modulate", Color.WHITE, blink_duration);
		t.tween_property(sprite, "self_modulate", eye_yellow, blink_duration);
		t.tween_property(sprite, "self_modulate", Color.WHITE, blink_duration);
		t.tween_property(sprite, "self_modulate", eye_yellow, blink_duration);
		t.tween_property(sprite, "self_modulate", Color.WHITE, blink_duration);
