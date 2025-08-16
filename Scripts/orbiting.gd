class_name orbiting extends Node2D

@export var speed:float = 1.0;

func _process(delta: float) -> void:
	rotation_degrees += speed * delta;
