class_name PushBlock extends RigidBody2D

@export var main:MainPush;
@export var block_value:int = 100000;
@export var real_dist:float = 750.0;
@export var push_duration:float = 0.2;
@export var kill_hitstop:float = 0.5;
@export var kill_shake:float = 10.0;

@onready var value_a: DynamicText = $ValuesContainer/ValueA
@onready var value_b: DynamicText = $ValuesContainer/ValueB
@onready var trail: Trail2D = $Trail

var push_values:Dictionary[int,int];
var remaining_movement:float = 0.0;
var current_tween:Tween = null;
var base_value:float = 0.0;
var kill_on_hit:bool = false;

func _ready() -> void:
	base_value = global_position.x;
	push_values[0] = block_value;
	push_values[1] = block_value;

	#value_a.self_modulate = main.balls[0].color;
	#value_b.self_modulate = main.balls[1].color;
	update_values_text();

func _process(delta: float) -> void:
	pass;

func _on_body_entered(other: Node) -> void:
	if(!other.is_in_group("BALL")):return;
	if(kill_on_hit): other.death(); return;

	var dir:int = -1 if other.position.y < self.position.y else 1;
	on_impact(other, dir);

func on_impact(ball:BattleBall, dir:int):
	if(current_tween != null):
		current_tween.kill();
		current_tween = null;

	var force:float = ball.scaling_damage * dir;

	# Utils.scale_number(ball);

	add_value(force, ball);

	check_for_victory(ball);

	if(kill_on_hit):
		force = sign(force) * (real_dist * 3.0) - abs(global_position.x);
	else:
		force = get_push_real_dist(force, ball);

	var dest:float = clamp(global_position.x + force, base_value - (real_dist*2.0), base_value + (real_dist*2.0));

	get_tree().create_timer(kill_hitstop).timeout.connect(execute_push.bind(dest));

func add_value(v:int, ball:BattleBall):
	v = abs(v);

	push_values[ball.team] -= v;
	push_values[(ball.team + 1) % 2] += v;

	update_values_text();

func get_push_real_dist(v: float, ball: BattleBall) -> float:
	return real_dist * (v / block_value);

func execute_push(dest:float):
	var tween:Tween = create_tween();
	tween.tween_property(self, "global_position:x", dest, push_duration if !kill_on_hit else push_duration * 5.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT);
	current_tween = tween;

func check_for_victory(ball:BattleBall):
	if(push_values[ball.team] > 0): return;
	kill_on_hit = true;
	trail.set_color(ball.color);
	trail.visible = true;
	main.global_hitstop(kill_hitstop);
	EventBus.camera_trigger_shake.emit(kill_shake);
	EventBus.ball_duel_winner.emit(ball.get_instance_id());

func update_values_text():
	value_a.format([str(push_values[0])]);
	value_b.format([str(push_values[1])]);
