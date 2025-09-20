class_name ComboCounterUI extends Control

@onready var number: RichTextLabel = $Node2D/Number
@onready var hits: RichTextLabel = $Node2D/Hits
@onready var progress_bar: ProgressBar = $Node2D/ProgressBar
@onready var color_rect: ColorRect = $Node2D/VBars/ColorRect3

var ball_owner:BattleBall = null;

func _ready() -> void:
	EventBus.ball_combo_up.connect(on_ball_combo_up);
	EventBus.ball_combo_reset.connect(on_ball_combo_reset);

func _process(_delta: float) -> void:
	if(!visible): return;
	progress_bar.value = Utils.ease_in_cubic(ball_owner.combo_remaining / ball_owner.max_combo_duration) * 100.0;

func init(o:BattleBall):
	visible = false;

	ball_owner = o;

	hits.modulate = ball_owner.color;
	progress_bar.get("theme_override_styles/fill").bg_color = ball_owner.color;

func on_ball_combo_up(id:int, _target:BattleBall):
	if(id != ball_owner.get_instance_id()): return;
	if(ball_owner.current_combo < 2): return;

	if(!visible):
		show_combo_counter();

	number.text = str(ball_owner.current_combo);
	gamefeel_tween(0.1, 30.0);

	pass;

func on_ball_combo_reset(id:int):
	if(id != ball_owner.get_instance_id()): return;

	if(visible):
		visible = false;

	pass;

func show_combo_counter():
	visible = true;


func gamefeel_tween(duration:float, dist:float):
	var t:Tween = create_tween();

	position.x += dist;

	t.tween_property(self, "position:x", position.x - dist, duration);
