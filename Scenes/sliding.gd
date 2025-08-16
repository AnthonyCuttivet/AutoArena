class_name Sliding extends HBoxContainer

@export var starting_duration: float = 10;
@export var speed: float = 0.0;
@export var numbers: Array[RichTextLabel];

var active: bool = false;
var duration: Elapser;

func _physics_process(delta: float) -> void:
	if (!active): return ;

	duration.update(delta);

	self.position.x -= speed * delta;

	for number in numbers:
		number.text = str(int(starting_duration - duration.elapsed));

func set_active():
	set_duration();
	active = true;
	self.visible = true;

func set_inactive():
	active = false;
	self.visible = false;

func set_duration():
	duration = Elapser.new();
	duration.duration = starting_duration;
	for number in numbers:
		number.text = str(int(starting_duration - duration.elapsed));
