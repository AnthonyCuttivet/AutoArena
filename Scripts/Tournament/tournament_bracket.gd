@tool
class_name TournamentBracket extends Node2D

# Number of contestants (must be a power of 2 for now)
@export var contestants: int = 8:
	set(value):
		contestants = max(2, value)
		_generate_bracket()

# Spacing config
@export var horizontal_spacing: float = 200.0
@export var vertical_spacing: float = 80.0
@export var line_width: float = 4.0

# Internal data
var _lines: Array[Line2D] = []
var _slots: Array[Label] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		_generate_bracket()

func _clear_bracket() -> void:
	for line: Line2D in _lines:
		if is_instance_valid(line):
			line.queue_free()
	_lines.clear()

	for slot: Label in _slots:
		if is_instance_valid(slot):
			slot.queue_free()
	_slots.clear()

func _generate_bracket() -> void:
	if not is_inside_tree():
		return

	_clear_bracket()

	var rounds: int = int(ceil(log(contestants) / log(2)))
	var match_count: int = contestants / 2

	# Create the first round slots
	for i: int in range(contestants):
		var slot: Label = Label.new()
		slot.text = "Player %d" % (i + 1)
		slot.position = Vector2(0, i * vertical_spacing)
		slot.modulate = Color.BLACK;
		add_child(slot)
		_slots.append(slot)

	# Generate match lines for each round
	var current_round_count: int = contestants
	var x_offset: float = horizontal_spacing
	while current_round_count > 1:
		for i: int in range(0, current_round_count, 2):
			var y1: float = (i) * vertical_spacing
			var y2: float = (i + 1) * vertical_spacing
			var mid_y: float = (y1 + y2) / 2.0

			# Vertical line
			var line_v: Line2D = Line2D.new()
			line_v.width = line_width
			line_v.default_color = Color.BLACK
			line_v.points = [Vector2(x_offset - horizontal_spacing, y1), Vector2(x_offset - horizontal_spacing, y2)]
			add_child(line_v)
			_lines.append(line_v)

			# Horizontal line
			var line_h: Line2D = Line2D.new()
			line_h.width = line_width
			line_h.default_color = Color.BLACK
			line_h.points = [Vector2(x_offset - horizontal_spacing, mid_y), Vector2(x_offset, mid_y)]
			add_child(line_h)
			_lines.append(line_h)

		current_round_count /= 2
		x_offset += horizontal_spacing
