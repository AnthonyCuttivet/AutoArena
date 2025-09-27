class_name WeaponPickaxe extends Weapon

@export var block_prefab: PackedScene;
@export var block_scale:float = 1.5;
@export var block_death_shake:float = 2.0;
@export var max_blocks:int = 1;

@export var pickaxes_textures:Array[Texture];
@export var blocks_textures:Array[Texture];
@export var block_spawn_positions:Array[Vector2];

@export var fx_confettis: MultiFX;

@export var sfx_level_up:SFX;
@export var sfx_block_spawn:SFX;
@export var sfx_block_hit:SFX;
@export var sfx_block_death:SFX;
@export var sfx_block_pickaxe:SFX;

var aled:bool = false;
var current_level:int = 0;
var space_state:PhysicsDirectSpaceState2D = null;
var requested_block_spawn:bool = false;
var active_blocks: Array[ProjectilePickaxeBlock];
var physics_params:PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new();

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);

func init(s:WeaponSettings, o:BattleBall) -> void:
	super.init(s,o);

	for i in block_spawn_positions.size():
		block_spawn_positions[i] = ball_owner.main.to_global(block_spawn_positions[i]);

	init_physics_params();

func _physics_process(delta: float) -> void:
	super._physics_process(delta);
	if(requested_block_spawn):
		requested_block_spawn = false;
		space_state = get_world_2d().direct_space_state;
		spawn_block();

func init_scaling_stat():
	scaling_stat_value = damage;
	ball_owner.update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	if(lifesteal && !lifesteal_active): return;
	damage += stat_scale_value;
	level_up();
	init_scaling_stat();

func level_up():
	if(current_level >= pickaxes_textures.size()): return;
	sprite_2d.texture = pickaxes_textures[get_level_index()];
	current_level += 1;
	AudioManager.play_sfx(sfx_level_up, "SFX");
	fx_confettis.emit();
	ball_owner.update_ui_sprite();

func on_weapon_hit_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	request_spawn_block();

func request_spawn_block():
	requested_block_spawn = true;

func spawn_block():
	if(active_blocks.size() == max_blocks): return;

	block_spawn_positions.shuffle();
	var pos:Vector2 = block_spawn_positions[0];
	for p in block_spawn_positions:
		if(is_free(p)):
			pos = p;
			break;
		pass

	var block:ProjectilePickaxeBlock = Utils.spawn_projectile(block_prefab, ball_owner, pos, PI / 2.0, ball_owner.main);
	block.scale *= block_scale;
	block.weapon_pickaxe = self;
	block.level = current_level + 1;
	if(current_level >= 1):
		block.sprite_2d.texture = blocks_textures[get_level_index()];

	active_blocks.push_back(block);

func is_free(pos: Vector2) -> bool:
	update_physics_params(pos)

	# print("----- " + str(pos) + " --------");
	# print(space_state.intersect_shape(physics_params));
	# print("-------------------------");

	return space_state.intersect_shape(physics_params).is_empty();

func init_physics_params():
	var shape : CircleShape2D = CircleShape2D.new();
	shape.radius = 100.0;

	physics_params.shape = shape
	physics_params.collide_with_areas = true
	physics_params.collide_with_bodies = true
	physics_params.collision_mask = 0x00000003;

func update_physics_params(pos:Vector2):
	physics_params.transform = Transform2D(0, pos);

func on_block_destroyed(from:BattleBall, block:ProjectilePickaxeBlock):
	ball_owner.main.global_hitstop(0.0, 0.15);
	ball_owner.main.spawn_fx_block_destroyed(block.global_position, 1.0, block.sprite_2d.texture);
	EventBus.camera_trigger_shake.emit(block_death_shake);
	AudioManager.play_sfx(sfx_block_death, "SFX");
	active_blocks.erase(block);
	block.destroy();

	if(from == ball_owner && current_level < block.level):
		scale_stat();
		AudioManager.play_sfx(sfx_block_pickaxe, "SFX");

func get_level_index() -> int:
	return current_level if current_level < blocks_textures.size() else blocks_textures.size() - 1;
