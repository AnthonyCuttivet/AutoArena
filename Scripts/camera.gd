class_name Camera extends Camera2D

@export var shake_fade: float = 10.0;

var shake_strength: float = 0.0;

func _ready():
	EventBus.camera_trigger_shake.connect(trigger_shake);
	pass

func _process(delta: float):
	if (shake_strength == 0): return ;

	shake_strength = lerp(shake_strength, 0.0, shake_fade * delta);
	offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength));

func trigger_shake(strength: float):
	if (strength <= shake_strength): return ;
	shake_strength = strength;
	# EventBus.set_chromatic_aberration.emit(3.0);
