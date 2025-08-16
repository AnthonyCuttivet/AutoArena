class_name BlackHoleBumper extends Node

@export var arena:Arena;
@export var bumper:Bumper;
@export var black_hole:BlackHole;

func _ready() -> void:
	black_hole.arena = arena;
