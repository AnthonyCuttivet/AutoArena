@tool
class_name BlockModeMCDig extends Node2D

@export_tool_button("Generate") var gen = generate;
@export_tool_button("Clear") var clear = clear_blocks;

@export var scene_root:Node2D;
@export var block_prefab:PackedScene;
@export var dimensions:Vector2i;
@export var ground_depth:int = 0;
@export var clusters: Array[MCClusterSettings];
@export var block_value_registry:Dictionary[Texture, int];
@export var block_sfx:Dictionary[Texture, AudioStream];
@export var distribution:Array[MCLayerSettings];

var p_cache:Vector2;
var layer:int;
var current_depth:int = 0;
var block_height:int = 64;
var cumulative_layers:Array[int] = [];
var blocks:Dictionary[Vector2i, MCBattleBlock] = {};
var active_tween:Tween = null;

func compute_cumulative_layers():
	cumulative_layers.clear();
	var sum:int = ground_depth;
	for d in distribution:
		sum = sum + d.size;
		cumulative_layers.push_back(sum);

func generate():
	current_depth = 0;
	layer = 0;
	p_cache = Vector2i.ZERO;
	compute_cumulative_layers();

	for y in dimensions.y:
		p_cache.y = y;
		for x in dimensions.x:
			p_cache.x = x;
			if(current_depth >= ground_depth):
				spawn_block(p_cache);
			# print(p_cache);
			if(x == dimensions.x - 1):
				current_depth += 1;
				if(y == cumulative_layers[layer] - 1):
					layer += 1;
		pass

	spawn_clusters();
	build_house();

	blocks.clear();

	pass;

func spawn_block(pos:Vector2i, forced_block:Texture = null):
	var block:MCBattleBlock = block_prefab.instantiate();
	self.add_child(block);
	blocks[pos] = block;

	if(forced_block == null):
		var block_choice:MCBlockSettings = Utils.weighted_pick(distribution[layer].layer_blocks);
		set_block_values(block, block_choice.tx)
	else:
		set_block_values(block, forced_block);

	block.position = pos * block.collider.shape.get_rect().size.x + (Vector2.ONE * block.collider.shape.get_rect().size.x / 2.0);
	block.parent = self;
	block.depth = pos.y;

	block.name = "Block";
	block.owner = scene_root;

func clear_blocks():
	for b in self.get_children():
		b.queue_free();

func spawn_clusters():
	for c in clusters:
		add_cluster(c);

func add_cluster(c:MCClusterSettings) -> void:
	var origin: Vector2i = Vector2i(randi_range(0, dimensions.x - 1), c.depth + ground_depth)

	# Random cluster size
	var size_x: int = randi_range(3, c.size.x + 3)
	var size_y: int = randi_range(0, c.size.y)

	for dx in range(-size_x, size_x + 1):
		for dy in range(-size_y, size_y + 1):
			var pos: Vector2i = origin + Vector2i(dx, dy)

			# Check bounds
			if pos.x < 0 or pos.x >= dimensions.x: continue
			if pos.y < 0 or pos.y >= dimensions.y: continue

			# Optional: give it a round/organic feel
			var dist:float = abs(dx) + abs(dy)
			var max_dist:float = size_x + size_y
			if randf() > 1.2 - float(dist) / float(max_dist):
				continue

			# Replace block
			set_block_values(blocks[pos], c.tx);

func build_house():
	var planks:Texture = block_value_registry.keys()[2];
	var wood:Texture = block_value_registry.keys()[1];
	var leaves:Texture = block_value_registry.keys()[0];

	spawn_block(Vector2(4,1), leaves);
	spawn_block(Vector2(4,2), leaves);
	spawn_block(Vector2(4,3), leaves);
	spawn_block(Vector2(4,4), wood);
	spawn_block(Vector2(4,5), wood);
	spawn_block(Vector2(3,1), leaves);
	spawn_block(Vector2(3,2), leaves);
	spawn_block(Vector2(5,1), leaves);
	spawn_block(Vector2(5,2), leaves);
	spawn_block(Vector2(5,3), leaves);
	spawn_block(Vector2(3,3), leaves);
	spawn_block(Vector2(2,3), leaves);
	spawn_block(Vector2(6,3), leaves);
	spawn_block(Vector2(2,2), leaves);
	spawn_block(Vector2(6,2), leaves);


	spawn_block(Vector2(22,2), wood);
	spawn_block(Vector2(22,3), wood);
	spawn_block(Vector2(22,4), wood);
	spawn_block(Vector2(22,5), wood);

	spawn_block(Vector2(28,2), wood);
	spawn_block(Vector2(28,3), wood);
	spawn_block(Vector2(28,4), wood);
	spawn_block(Vector2(28,5), wood);

	spawn_block(Vector2(22,1), wood);
	spawn_block(Vector2(23,1), wood);
	spawn_block(Vector2(24,1), wood);
	spawn_block(Vector2(25,1), wood);
	spawn_block(Vector2(26,1), wood);
	spawn_block(Vector2(27,1), wood);
	spawn_block(Vector2(28,1), wood);

	spawn_block(Vector2(23,2), planks);
	spawn_block(Vector2(23,3), planks);
	spawn_block(Vector2(23,4), planks);
	spawn_block(Vector2(23,5), planks);
	spawn_block(Vector2(24,2), planks);
	spawn_block(Vector2(24,3), planks);

	spawn_block(Vector2(25,2), planks);
	spawn_block(Vector2(25,3), planks);
	spawn_block(Vector2(25,4), planks);
	spawn_block(Vector2(25,5), planks);
	spawn_block(Vector2(26,2), planks);
	spawn_block(Vector2(26,3), planks);
	spawn_block(Vector2(26,4), planks);
	spawn_block(Vector2(26,5), planks);
	spawn_block(Vector2(27,2), planks);
	spawn_block(Vector2(27,3), planks);
	spawn_block(Vector2(27,4), planks);
	spawn_block(Vector2(27,5), planks);

func set_block_values(b:MCBattleBlock, tx:Texture):
	b.sprite.texture = tx;
	b.block_value = block_value_registry[tx];
	b.stx = b.sprite.texture;
	b.sfx_hit.audio_stream.remove_stream(0);
	b.sfx_hit.audio_stream.add_stream(0, block_sfx[tx]);

func on_block_destroyed(by:BattleBall, block:MCBattleBlock):
	if(block.depth == dimensions.y - 1):
		var opponent:BattleBall = scene_root.get_opponent(by.get_instance_id());
		opponent.can_respawn = false;
		opponent.death();
		scene_root.end_game();
		return;

	if(by.claimed_blocks[block.sprite.texture] == false):
		by.claimed_blocks[block.sprite.texture] = true;
		update_bb_blocks_ui(by);

		for i in by.weapon.scale_stat_multiplier:
			by.weapon.scale_stat(true);

		# print(Utils.pf() + " " + by.weapon_settings.name + " Claimed block " + block.sprite.texture.resource_path);

	if(block.depth > current_depth):
		current_depth = block.depth;

func init_bb_blocks_ui(ball:BattleBall):
	for i in ball.bb_blocks_ui.get_child_count():
		ball.bb_blocks_ui.get_child(i).texture = block_value_registry.keys()[i];
		ball.bb_blocks_ui.get_child(i).self_modulate.a = 0.3;
		ball.claimed_blocks[block_value_registry.keys()[i]] = false;

func update_bb_blocks_ui(ball:BattleBall):
	for i in ball.claimed_blocks.keys().size():
		ball.bb_blocks_ui.get_child(i).self_modulate.a = 1.0 if ball.claimed_blocks.values()[i] else 0.3;
