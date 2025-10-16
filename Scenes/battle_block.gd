class_name BattleBlock extends RigidBody2D

@export var main:Main;
@export var block_value:int = 1;
@export var block_death_shake:float = 1.0;
@export var sfx_break:SFX;
@export var value:DynamicText;

@onready var polygon_2d: Polygon2D = $CollisionShape2D/Polygon2D2
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: BattleBlockHurtbox = $Hurtbox

var current_value:int = 0;
var block_index:int = 0;
var team:int = 0;

func _ready() -> void:
	hurtbox.ball_owner = BattleBall.new();
	hurtbox.ball_owner.health = 99;
	hurtbox.ball_owner.team = -99;
	hurtbox.ball_owner.hp_text = value;
	hurtbox.ball_owner.unkillable = true;

	current_value = block_value;
	update_value_text();
	EventBus.ball_damaged.connect(on_damaged_received);

func _on_body_entered(other: Node) -> void:
	# if(!other.is_in_group("BALL")):return;
	# on_impact(other);
	pass;

func on_impact(ball:BattleBall, amount:int):
	if(ball.team != team): return;

	current_value -= amount;
	EventBus.ball_duel_scale.emit(ball.get_instance_id());

	if(current_value <= 0):
		block_death(ball);
		return;

	update_value_text();
	#update_block_color(ball);

func block_death(ball:BattleBall):
	get_tree().get_current_scene().global_hitstop(0.01, 0.1);
	EventBus.camera_trigger_shake.emit(block_death_shake * block_index);
	AudioManager.play_sfx(sfx_break, "SFX");
	queue_free();
	EventBus.block_destroyed.emit(ball.get_instance_id(), block_index);

func update_value_text():
	value.format([Utils.format_number_with_dots(current_value)]);

#func update_block_color(ball:BattleBall):
	#polygon_color.color = ball.color;
	#if(current_value < ball.scaling_damage):
		#polygon_color.color.a = 0.9;
	#else:
		#polygon_color.color.a = 1.0 - (current_value/float(block_value));

func on_damaged_received(id:int, _amount:int, _from:int, _slot_id:int):
	if(id != hurtbox.ball_owner.get_instance_id()): return;

	on_impact(main.get_ball_by_id(_from), _amount);
