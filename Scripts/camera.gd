class_name Camera extends Camera2D

@export var shake_fade: float = 10.0;

@onready var phantom_camera_2d: PhantomCamera2D = $"../PhantomCamera2D"

var shake_strength: float = 0.0;
var shake_direction:Vector2 = Vector2.ONE;
var min_zoom:Vector2 = Vector2.ONE;

func _ready():
	EventBus.camera_trigger_shake.connect(trigger_shake);
	rotation_degrees -= 90;
	pass

func _process(delta: float):
	if (shake_strength != 0):
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta);
		offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength)) * shake_direction;

func trigger_shake(strength: float, direction:Vector2 = Vector2.ONE):
	if (strength <= shake_strength): return ;
	shake_strength = strength;
	shake_direction = direction;

func set_camera_zoom(v:Vector2):
	zoom = v;
	phantom_camera_2d.zoom = v;
	min_zoom = v;
