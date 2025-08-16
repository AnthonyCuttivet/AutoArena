class_name BlackRedSpark extends Node2D

@export var rot_speed:float = 50.0;

@onready var r: Node2D = $Root

func _process(delta: float) -> void:
	r.rotate(deg_to_rad(rot_speed*delta));

func set_root_dist(v:float):
	r.position.x = v;
