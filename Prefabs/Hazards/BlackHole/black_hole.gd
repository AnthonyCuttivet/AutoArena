class_name BlackHole extends Node2D

@export var strength: float = 0.25;
@export var max_range: float = 800.0;

@onready var arena: Arena;
@onready var sprite: Sprite2D = $Sprite2D

var active: bool = false;

func _ready():
	EventBus.match_started.connect(set_active.bind(true));
	sprite.scale = Vector2.ONE * max_range * 2.0;
	pass

func _physics_process(delta: float) -> void:
	if (!active): return ;

	for ball in arena.game_manager.balls:
		if (ball == null): continue ;
		apply_force_to(ball);

func set_active(v: bool):
	active = v;

func apply_force_to(body: RigidBody2D):
	var dir: Vector2 = global_position.direction_to(body.global_position);
	var dist: float = global_position.distance_to(body.global_position);

	if dist < max_range:
		var force = (body.linear_velocity.length() * strength) * (1.0 - (dist / max_range));
		var pull = - dir * force; # Negative to attract
		body.apply_central_impulse(pull);
