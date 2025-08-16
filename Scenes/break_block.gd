class_name BreakBlock extends RigidBody2D

@export var block_value:int = 1;
@export var block_death_shake:float = 1.0;
@export var sfx_break:SFX;

@onready var value: DynamicText = $Value
@onready var polygon_2d: Polygon2D = $CollisionShape2D/Polygon2D
@onready var polygon_color: Polygon2D = $CollisionShape2D/PolygonColorOverlay
@onready var collider: CollisionShape2D = $CollisionShape2D

var main:MainPush = null;
var current_value:int = 0;
var block_index:int = 0;
var team:int = -1;

func init() -> void:
	current_value = block_value;
	update_value_text();

func _on_body_entered(other: Node) -> void:
	if(!other.is_in_group("BALL")):return;
	on_impact(other);

func on_impact(ball:BattleBall):
	if(ball.team != team): return;

	current_value -= ball.scaling_damage;
	EventBus.ball_duel_scale.emit(ball.get_instance_id());

	if(current_value <= 0):
		block_death(ball);
		return;

	update_value_text();
	update_block_color(ball);

func block_death(ball:BattleBall):
	main.global_hitstop(0.1);
	EventBus.camera_trigger_shake.emit(block_death_shake * block_index);
	AudioManager.play_sfx(sfx_break, "SFX");
	queue_free();
	EventBus.block_destroyed.emit(ball.get_instance_id(), block_index);

func update_value_text():
	value.format([Utils.format_number_with_dots(current_value)]);

func update_block_color(ball:BattleBall):
	polygon_color.color = ball.color;
	if(current_value < ball.scaling_damage):
		polygon_color.color.a = 0.9;
	else:
		polygon_color.color.a = 1.0 - (current_value/float(block_value));
