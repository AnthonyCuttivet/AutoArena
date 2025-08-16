class_name Bumper extends Node

@export var bump_multiplier: float = 1.5;

@export_group("Feedback")
@export var min_size: float = 0.9;
@export var max_size: float = 1.1;
@export var duration: float = 0.1;

@onready var area_2d: Area2D = $Area2D;
@onready var visual: Node2D = $Visual
@onready var bg: Sprite2D = $Visual/BG

func _ready() -> void:
	area_2d.body_entered.connect(_on_body_entered);

func _on_body_entered(body):
	if (body is Ball):
		start_bumped_feedback();
		apply_on_bump_effect(body);
		body.apply_impulse(body.linear_velocity * bump_multiplier);
		EventBus.play_player_sfx.emit(body.player_id, "bounce");

func apply_on_bump_effect(_body: Ball):
	pass ;

func start_bumped_feedback():
	var tween: Tween = create_tween();

	tween.tween_property(visual, "scale", Vector2.ONE * min_size, duration).set_trans(Tween.TRANS_CUBIC);
	tween.tween_property(visual, "scale", Vector2.ONE * max_size, duration).set_trans(Tween.TRANS_CUBIC);
	tween.tween_property(visual, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_SPRING);

	tween.play();
	pass ;
