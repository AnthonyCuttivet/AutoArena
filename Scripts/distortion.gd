class_name Distortion extends ColorRect

@export var value:float = 0.08;
@export var cycle_duration:float = 10.0;

var breathe_tween: Tween

func _ready() -> void:
	_start_breathe();

func _start_breathe() -> void:
	breathe_tween = create_tween().set_loops()
	breathe_tween.tween_method(
		func(v: float) -> void:
			self.material.set_shader_parameter("strength", v),
		0.0, value, cycle_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathe_tween.tween_method(
		func(v: float) -> void:
			self.material.set_shader_parameter("strength", v),
		value, 0.0, cycle_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
