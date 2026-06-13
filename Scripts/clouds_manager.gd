class_name CloudsManager extends Control

@export var cloud_scene : PackedScene
@export var cloud_textures : Array[Texture2D]

var layer_data = [
	{
		"speed": 2.0,
		"scale": 1.8,
		"color": Color(0.97,0.97,0.97,0.15),
		"count": 3
	},
	{
		"speed": 7.0,
		"scale": 1.0,
		"color": Color(0.99,0.99,0.99,0.35),
		"count": 12
	},
	{
		"speed": 12.0,
		"scale": .6,
		"color": Color(1.0,1.0,1.0,0.8),
		"count": 15
	}
]

@export var world_width := 3000
@export var world_height := 800

@export var wind_direction := 1.0


func _ready():
	wind_direction = 1 if randf_range(-1,1) > 0 else -1;

	for layer in layer_data:
		spawn_layer(layer)

func spawn_layer(layer):
	for i in layer.count:
		var cloud:MCCloud = cloud_scene.instantiate()

		add_child(cloud)

		cloud.position = Vector2(
			randf() * world_width,
			randf() * world_height
		)

		cloud.speed = (1.0 * layer.speed) * randf_range(0.5, 2.0) * 2.0;
		cloud.wind_dir = wind_direction
		cloud.world_width = world_width

		cloud.scale = Vector2.ONE * (
			layer.scale * randf_range(0.8, 1.2)
		)

		cloud.modulate = layer.color

		var sprite = cloud.sprite;
		sprite.texture = cloud_textures.pick_random()
