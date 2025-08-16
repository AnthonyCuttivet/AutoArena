# BallManager.gd - Simplified high-performance approach
class_name BallManager extends Node2D

# Ball data stored in packed arrays for cache efficiency
var positions: PackedVector2Array = []
var velocities: PackedVector2Array = []
var colors: PackedColorArray = []
var teams: PackedInt32Array = []

var ball_count: int = 0
var arena: ArenaCircle = null

# Pre-calculated constants
var max_y_vel: float
var circle_center: Vector2
var circle_radius: float
var ball_radius: float
var collision_radius: float

# Ball texture (shared by all balls)
@export var ball_texture: Texture2D
@export var ball_pool_size: int = 4000 # Adjust based on expected max balls
@export var fx_pool_size: int = 200
@export var sprite_scale: Vector2 = Vector2(0.046, 0.046) # Scale for sprites
@export var trail_prefab: PackedScene;
@export var fx_0: PackedScene;
@export var fx_1: PackedScene;

# Pool for reusing sprite nodes
var sprite_pool: Array[Sprite2D] = []
var active_sprites: Array[Sprite2D] = []
var trails_pool: Array[Line2D] = []
var active_trails: Array[Line2D] = []
var fx_pool_no: Array[GPUParticles2D] = []
var fx_pool_yes: Array[GPUParticles2D] = []

var start_angle_rad: float = 0.0
var end_angle_rad: float = 0.0
var out_radius: float = 0.0
var removal_indices: PackedInt32Array = []

func _ready():
	setup_pools()

func setup_pools():
	# Pre-create sprites to avoid runtime allocation
	for i in range(ball_pool_size): # Adjust based on max expected balls
		var sprite = Sprite2D.new()
		sprite.texture = ball_texture
		sprite.visible = false
		sprite.scale = sprite_scale;
		add_child(sprite)
		sprite_pool.append(sprite)

	for i in range(fx_pool_size / 2):
		var particles = fx_0.instantiate();
		if particles:
			particles.finished.connect(return_fx_to_pool.bind(particles, 0));
			add_child(particles)
			particles.visible = false;
			particles.global_rotation_degrees = 90.0;
			fx_pool_no.append(particles)

	for i in range(fx_pool_size / 2):
		var particles = fx_1.instantiate();
		if particles:
			particles.finished.connect(return_fx_to_pool.bind(particles, 1));
			add_child(particles)
			particles.visible = false;
			particles.global_rotation_degrees = 90.0;
			fx_pool_yes.append(particles)

func init_arena(arena_ref: ArenaCircle):
	arena = arena_ref
	# Pre-calculate constants
	circle_center = arena.circle_center
	circle_radius = arena.circle_radius
	ball_radius = arena.ball_radius
	collision_radius = circle_radius - ball_radius
	max_y_vel = arena.max_y_vel
	start_angle_rad = deg_to_rad(arena.gap_angle_start - 90.0)
	end_angle_rad = deg_to_rad(arena.gap_angle_end - 90.0)
	out_radius = circle_radius * 1.01 + ball_radius

func add_ball(pos: Vector2, vel: Vector2, color: Color, team: int):
	if sprite_pool.is_empty():
		print("Warning: Sprite pool exhausted!")
		return

	# Get sprite from pool
	var sprite = sprite_pool.pop_back()
	sprite.position = pos
	sprite.modulate = color
	sprite.visible = true
	active_sprites.append(sprite)

	# Store data
	positions.append(pos)
	velocities.append(vel)
	colors.append(color)
	teams.append(team)
	ball_count += 1

func _physics_process(delta: float):
	if not arena or arena.over:
		cleanup_all_balls()
		return

	update_all_balls(delta)

func update_all_balls(delta: float):
	removal_indices.clear()
	for i in range(ball_count):
		# Update velocity with gravity (clamped)
		velocities[i].y = clamp(velocities[i].y + arena.gravity, -max_y_vel, max_y_vel)

		# Update position
		positions[i] += velocities[i] * delta

		# Update sprite position
		active_sprites[i].position = positions[i]

		# Check physics and boundaries
		if update_ball_physics(i):
			removal_indices.append(i)

	# Remove dead balls (process in reverse)
	for i in range(removal_indices.size() - 1, -1, -1):
		remove_ball(removal_indices[i])

func update_ball_physics(index: int) -> bool:
	var pos: Vector2 = positions[index]

	# Quick squared distance check
	var dx: float = circle_center.x - pos.x
	var dy: float = circle_center.y - pos.y
	var dist_squared: float = dx * dx + dy * dy

	if (dist_squared < (circle_radius - ball_radius) * (circle_radius - ball_radius)):
		return false;

	# Check if ball is out
	if dist_squared > out_radius * out_radius:
		spawn_death_effect(pos, teams[index])
		arena.on_ball_out_optimized(teams[index])
		return true

	# Check hole collision first (cheaper)
	if is_in_hole_fast(Vector2(dx, dy)):
		return false

	# Circle collision - only check if ball is actually outside the allowed area
	if dist_squared > collision_radius * collision_radius:
		handle_circle_collision(index, Vector2(dx, dy))

	return false

func handle_circle_collision(index: int, n: Vector2):
	var vel: Vector2 = velocities[index]
	var t: Vector2 = Vector2(-n.y, n.x);
	positions[index] = circle_center + (collision_radius - ball_radius) * -n.normalized();
	var p: Vector2 = vel.dot(t) / t.dot(t) * t;
	velocities[index] = 2 * p - vel;

	arena.play_sfx()

	# Special case for 2 balls
	# if arena.active_balls_count == 2:
	# 	var hole_pos = get_hole_pos_fast()
	# 	var d = hole_pos - positions[index]
	# 	velocities[index] += d * 0.9

func is_in_hole_fast(d: Vector2) -> bool:
	var ball_angle: float = atan2(-d.y, -d.x)

	if start_angle_rad > end_angle_rad:
		end_angle_rad += TAU

	return (start_angle_rad <= ball_angle and ball_angle <= end_angle_rad) or (start_angle_rad <= ball_angle + TAU and ball_angle + TAU <= end_angle_rad)

func get_hole_pos_fast() -> Vector2:
	return circle_center + Vector2(cos(start_angle_rad), sin(start_angle_rad)) * collision_radius

func spawn_death_effect(pos: Vector2, team: int):
	if (team == 0 && fx_pool_no.is_empty()):
		return ;

	if (team == 1 && fx_pool_yes.is_empty()):
		return ;

	var fx: GPUParticles2D;

	if (team == 0):
		fx = fx_pool_no.pop_back();
	else:
		fx = fx_pool_yes.pop_back();

	fx.visible = true;
	fx.position = pos;
	fx.restart();

	return ;

func return_fx_to_pool(fx: GPUParticles2D, team: int):
	fx.visible = false;
	if (team == 0):
		fx_pool_no.append(fx);
	else:
		fx_pool_yes.append(fx);

func remove_ball(index: int):
	if index >= ball_count or index < 0:
		return

	# Return sprite to pool
	var sprite: Sprite2D = active_sprites[index]
	sprite.visible = false
	sprite_pool.append(sprite)

	# Swap-remove for O(1) operation
	var last_index: int = ball_count - 1
	if index != last_index:
		positions[index] = positions[last_index]
		velocities[index] = velocities[last_index]
		colors[index] = colors[last_index]
		teams[index] = teams[last_index]
		active_sprites[index] = active_sprites[last_index]

	# Remove last elements
	positions.resize(last_index)
	velocities.resize(last_index)
	colors.resize(last_index)
	teams.resize(last_index)
	active_sprites.resize(last_index)

	ball_count -= 1

func cleanup_all_balls():
	# Return all sprites to pool
	for sprite in active_sprites:
		sprite.visible = false
		sprite_pool.append(sprite)

	# Clear all data
	positions.clear()
	velocities.clear()
	colors.clear()
	teams.clear()
	active_sprites.clear()
	ball_count = 0
