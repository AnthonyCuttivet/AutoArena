extends Node2D

@export var speed:float = 50.0;
@export var amplitude:float = 250.0;
@export var debug:bool = false;

var original_pos:Vector2;
var dir:int = 1;

func _ready() -> void:
	original_pos = global_position;

func _process(delta: float) -> void:
	global_position.y += speed * dir * delta;
	if(abs(global_position.y - original_pos.y) >= amplitude):
		dir *= -1;
	
	if(debug):
		DebugDraw2D.circle_filled(global_position, 10.0, 16, Color.AQUAMARINE);
