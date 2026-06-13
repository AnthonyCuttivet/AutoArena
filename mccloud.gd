class_name MCCloud extends Control

@export var sprite:TextureRect;

var speed :float = 0.0
var wind_dir := 1.0
var world_width := 0.0
var world_height := 0.0

func _process(delta):
	position.x += speed * wind_dir * delta

	if wind_dir > 0 and position.x > world_width:
		recycle_left()

	elif wind_dir < 0 and position.x < (-world_width):
		recycle_right()

func recycle_left():
	position.x = -world_width
	sprite.flip_h = true if randi_range(0,1) == 1 else false;

func recycle_right():
	position.x = world_width
	sprite.flip_h = true if randi_range(0,1) == 1 else false;
