class_name Afterimage extends Node2D

@export var active:bool = false;
@export var source_sprite: Sprite2D
@export var afterimage_lifetime := 0.2
@export var spawn_interval := 0.05
@export var opacity:float = 0.5;
@export var use_gradient:bool = false;
@export var gradient: Gradient;
@export var continuous:bool = true;

@onready var root: CollisionShape2D = $".."
@onready var ball_owner: BattleBall = $"../.."

var time_since_last := 0.0
var spawn_interval_total:float = 0.0;

func _process(delta):
	if(!active):return;
	if(ball_owner.dead): return;
	time_since_last += delta
	if time_since_last >= spawn_interval:
		time_since_last = (time_since_last - spawn_interval) if continuous else 0.0;
		spawn_afterimage()

func setup_afterimages(_use_gradient:bool, _interval:float, _opacity:float):
	use_gradient = _use_gradient;
	spawn_interval = _interval;
	opacity = _opacity;

func spawn_afterimage():
	var img = Sprite2D.new()
	img.texture = source_sprite.texture
	img.global_position = source_sprite.global_position
	#img.global_rotation = source_sprite.global_rotation
	img.scale = root.scale;

	if(use_gradient && gradient != null):
		img.modulate = gradient.sample(fmod(spawn_interval_total * 21.9,1.0));
		img.modulate.a = opacity;
	else:
		img.modulate = Color(source_sprite.self_modulate.r, source_sprite.self_modulate.g, source_sprite.self_modulate.b, opacity)

	get_tree().current_scene.special_effects_parent.add_child(img);

	# Fade out and delete
	img.create_tween().tween_property(img, "self_modulate:a", 0.0, afterimage_lifetime).finished.connect(func(): img.queue_free())

	spawn_interval_total += spawn_interval;
