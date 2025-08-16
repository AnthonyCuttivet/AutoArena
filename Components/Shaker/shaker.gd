class_name Shaker extends Node

var shake_strength: float = 0.0;
var shake_fade: float = 10.0;

func _physics_process(delta: float) -> void:
	if (shake_strength == 0):
		self.queue_free();

	shake_strength = lerp(shake_strength, 0.0, shake_fade * delta);
	get_parent().sprite.position = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength));
