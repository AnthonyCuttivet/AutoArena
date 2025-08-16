class_name Cameo extends Node2D

@export var speed:float;
@export var rot_speed:float;
@export var ball:Node2D;
@export var weapon_root:Node2D;

func _physics_process(delta: float) -> void:
	ball.position.x += speed * delta;
	weapon_root.rotation_degrees += 360.0 * rot_speed * delta;

	if(ball.position.x >= 20000.0) : queue_free();
