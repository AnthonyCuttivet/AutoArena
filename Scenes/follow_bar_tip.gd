@tool
class_name FollowBarTip extends ColorRect

@export var bar:TextureProgressBar;
@export var x_offset:float;

func _process(delta: float) -> void:
	position.x = size.x + bar.size.x * (bar.value / bar.max_value);
