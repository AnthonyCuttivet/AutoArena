@tool
class_name BlockModeMCDig extends Node2D

@export_tool_button("Generate") var gen = generate;
@export_tool_button("Clear") var clear = clear_blocks;

@export var scene_root:Node2D;
@export var block_prefab:PackedScene;
@export var layers_tx:Array[Texture];
@export var layers_value:Array[int];
@export var layers_dist:Array[int];
@export var dimensions:Vector2i;
@export var spacing:float = 1.0;
@export var distribution:Array[MCLayerSettings];

var p_cache:Vector2;
var layer:int;
var current_depth:int = 0;
var block_height:int = 64;
var cumulative_layers:Array[int] = [];

func compute_cumulative_layers():
	cumulative_layers.clear();
	var sum:int = 0;
	for v in layers_dist:
		sum = sum + v;
		cumulative_layers.push_back(sum);

func generate():
	layer = 0;
	p_cache = Vector2.ZERO;
	compute_cumulative_layers();

	for y in dimensions.y:
		p_cache.y = y;
		for x in dimensions.x:
			p_cache.x = x;
			spawn_block(p_cache);
			# print(p_cache);
			if(x == dimensions.x - 1 && y == cumulative_layers[layer] - 1):
				layer += 1;
		pass

	pass;

func spawn_block(pos:Vector2):
	var block:MCBattleBlock = block_prefab.instantiate();
	self.add_child(block);

	var block_choice:MCBlockSettings = Utils.weighted_pick(distribution[layer].layer_blocks);

	block.position = pos * block.collider.shape.get_rect().size.x + (Vector2.ONE * block.collider.shape.get_rect().size.x / 2.0);
	block.position += Vector2(pos.x * spacing, pos.y * spacing);
	block.parent = self;
	block.depth = pos.y;
	block.sprite.texture = block_choice.tx;
	block.block_value = block_choice.value;
	block.stx = block.sprite.texture;

	block.name = "Block";
	block.owner = scene_root;

func clear_blocks():
	for b in self.get_children():
		b.queue_free();

func on_block_destroyed(block:MCBattleBlock):
	if(block.depth > current_depth):
		current_depth = block.depth;
		go_deeper();

func go_deeper():
	var t:Tween = create_tween();
	t.tween_property(self, "position:y", self.position.y - block_height, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK);
