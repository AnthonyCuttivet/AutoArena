class_name ComboCounterUI extends Control

@export var is_left:bool = false;

@onready var number: RichTextLabel = $Node2D/Number
@onready var hits: RichTextLabel = $Node2D/Hits
@onready var progress_bar: ProgressBar = $Node2D/ProgressBar
@onready var color_rect: ColorRect = $Node2D/VBars/ColorRect3

var ball_owner:BattleBall = null;
var base_position:Vector2;
var active:bool = false;
var ui_tween:Tween = null;

func _ready() -> void:
	base_position = position;

	set_process(false);
	reset_ui(false);

func _process(_delta: float) -> void:
	if(!visible): return;
	progress_bar.value = ball_owner.combo_remaining / ball_owner.max_combo_duration * 100.0;

func init(o:BattleBall):
	set_process(true);
	reset_ui(false);

	EventBus.ball_combo_up.connect(on_ball_combo_up);
	EventBus.ball_combo_reset.connect(on_ball_combo_reset);

	ball_owner = o;

	hits.modulate = ball_owner.color;
	progress_bar.get("theme_override_styles/fill").bg_color = ball_owner.color;

func on_ball_combo_up(id:int, _target:BattleBall):
	if(id != ball_owner.get_instance_id()): return;
	if(ball_owner.current_combo < 2): return;

	active = true;

	kill_tween();

	if(!visible):
		show_combo_counter();

	progress_bar.value = 100.0;
	number.text = str(ball_owner.current_combo);
	gamefeel_tween(0.1, 30.0 if is_left else -30.0);

	pass;

func on_ball_combo_reset(id:int):
	if(id != ball_owner.get_instance_id()): return;

	if(visible):
		active = false;
		get_tree().create_timer(0.2).timeout.connect(hide_combo_counter.bind(30.0 if is_left else -30.0));

	pass;

func show_combo_counter():
	active = true;
	reset_ui(true);

func hide_combo_counter(dist:float):
	if(active): return;

	kill_tween();

	ui_tween = create_tween();
	ui_tween.tween_property(self, "position:x", position.x - dist, 0.2);
	ui_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.08).set_delay(0.12);
	ui_tween.finished.connect(reset_ui.bind(false));

func reset_ui(s:bool):
	kill_tween();
	visible = s;
	modulate.a = 1.0;
	position.x = base_position.x;

func gamefeel_tween(duration:float, dist:float):
	reset_ui(true);
	position.x += dist;
	ui_tween = create_tween();
	ui_tween.tween_property(self, "position:x", position.x - dist, duration);

func kill_tween():
	if ui_tween and ui_tween.is_running():
		ui_tween.kill()
	ui_tween = null
