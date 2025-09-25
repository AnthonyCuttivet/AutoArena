class_name WeaponPickaxe extends Weapon

@export var block_prefab: PackedScene;
@export var block_scale:float = 1.5;
@export var block_death_shake:float = 2.0;

@export var pickaxes_textures:Array[Texture];
@export var blocks_textures:Array[Texture];
@export var block_spawn_positions:Array[Vector2];

@export var sfx_block_hit:SFX;
@export var sfx_block_death:SFX;

var aled:bool = false;
var current_level:int = 0;
var space_state:PhysicsDirectSpaceState2D = null;
var requested_block_spawn:bool = false;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);

func init(s:WeaponSettings, o:BattleBall) -> void:
	super.init(s,o);
	get_tree().create_timer(0.5).timeout.connect(request_spawn_block);

	for i in block_spawn_positions.size():
		block_spawn_positions[i] = ball_owner.main.to_global(block_spawn_positions[i]);

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
	sprite_2d.texture = pickaxes_textures[get_level_index()];
	current_level += 1;
	init_scaling_stat();

func on_weapon_hit_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	scale_stat();

func request_spawn_block():
	requested_block_spawn = true;

func spawn_block():
	block_spawn_positions.shuffle();
	var pos:Vector2 = block_spawn_positions[0];
	for p in block_spawn_positions:
		if(is_free(p, 50.0)):
			pos = p;
			break;
		pass

	var block:ProjectilePickaxeBlock = Utils.spawn_projectile(block_prefab, ball_owner, pos, PI / 2.0, ball_owner.main);
	block.scale *= block_scale;
	block.weapon_pickaxe = self;
	if(current_level >= 1):
		block.sprite_2d.texture = blocks_textures[get_level_index()];

func is_free(pos: Vector2, radius: float) -> bool:
	var shape : CircleShape2D = CircleShape2D.new()
	shape.radius = radius

	var params :PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0, pos)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.collision_mask = 0x00000003;

	print("----- " + str(pos) + " --------");
	print(space_state.intersect_shape(params));
	print("-------------------------");

	return space_state.intersect_shape(params).is_empty();


func get_level_index() -> int:
	return current_level if current_level < blocks_textures.size() else blocks_textures.size() - 1;
