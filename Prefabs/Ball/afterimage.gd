class_name Afterimage extends Node2D

@export var active:bool = false;
@export var source_sprite: Sprite2D
@export var afterimage_lifetime := 0.2
@export var spawn_interval := 0.05

@onready var root: CollisionShape2D = $".."

var time_since_last := 0.0

func _process(delta):
	if(!active):return;
	time_since_last += delta
	if time_since_last >= spawn_interval:
		time_since_last = time_since_last - spawn_interval;
		spawn_afterimage()

func spawn_afterimage():
	var img = Sprite2D.new()
	img.texture = source_sprite.texture
	img.global_position = source_sprite.global_position
	#img.global_rotation = source_sprite.global_rotation
	img.scale = root.scale;
	img.modulate = Color(source_sprite.self_modulate.r, source_sprite.self_modulate.g, source_sprite.self_modulate.b, 0.5)

	get_tree().current_scene.special_effects_parent.add_child(img);

	# Fade out and delete
	img.create_tween().tween_property(img, "self_modulate:a", 0.0, afterimage_lifetime).finished.connect(func(): img.queue_free())
