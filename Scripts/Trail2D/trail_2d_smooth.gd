class_name Trail2DSmooth extends Line2D

@export var length: int = 50
@export var ball: Node2D          # the ball node (stable position reference)
@export var weapon: Node2D        # the weapon node (used for rotation + offset direction only)
@export var blade_offset: float = 40.0  # distance from ball center to blade tip

# Smoothing — averages position over N frames before placing a point
@export var smoothing_samples: int = 3

# Minimum distance between points — prevents jitter from spawning
# redundant points during hitstop/scale pulses
@export var min_point_distance: float = 2.0

var _smooth_buffer: Array[Vector2] = []
var active: bool = true
var base_length: int = 0

func _init():
	base_length = length

func _ready():
	top_level = true  # decouple from parent transform entirely

func _process(_delta: float) -> void:
	if not active or not ball or not weapon:
		return

	# Compute blade tip in world space from stable ball position +
	# weapon rotation direction — immune to weapon scale/position jitter
	var direction = Vector2.RIGHT.rotated(weapon.global_rotation)
	var blade_tip = ball.global_position + direction * blade_offset

	# Accumulate smoothing samples
	_smooth_buffer.append(blade_tip)
	if _smooth_buffer.size() > smoothing_samples:
		_smooth_buffer.pop_front()

	# Average the buffer for a smoothed position
	var smoothed = Vector2.ZERO
	for p in _smooth_buffer:
		smoothed += p
	smoothed /= _smooth_buffer.size()

	# Only add a point if we've moved enough — filters out
	# jitter that spawns dense overlapping points during game feel effects
	if get_point_count() == 0 or smoothed.distance_to(get_point_position(get_point_count() - 1)) >= min_point_distance:
		add_point(smoothed)

	while get_point_count() > length:
		remove_point(0)

func set_active(s: bool):
	active = s
	length = base_length if s else 0
	if not s:
		clear_points()

func set_color(color: Color):
	if not gradient:
		return
	var alphas: Array[float] = [gradient.colors[0].a, gradient.colors[1].a]
	gradient.colors[0] = color
	gradient.colors[0].a = alphas[0]
	gradient.colors[1] = color
	gradient.colors[1].a = alphas[1]
