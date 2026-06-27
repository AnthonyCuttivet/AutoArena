class_name FixedPos extends Node2D

@export var dist:float;
@export var weapon:Weapon;

var ball:BattleBall = null;

func _physics_process(delta: float) -> void:
	self.global_position = Vector2.ZERO;
