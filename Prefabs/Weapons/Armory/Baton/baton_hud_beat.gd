class_name BatonHUDBeat extends Control

@export var notes_pool_size:int = 10;
@export var note_speed_mult:float = 1.2;

@onready var note: BatonMusicNote = $ParentMask/MusicNote
@onready var lines_container: Control = $ParentMask/LinesContainer
@onready var beat_lines_parent: Control = $ParentMask/BeatLinesParent
@onready var beat_line_l: Line2D = $ParentMask/BeatLinesParent/Line2D
@onready var beat_line_r: Line2D = $ParentMask/BeatLinesParent/Line2D2
@onready var notes_pool_parent: Control = $ParentMask/NotesPool

var weapon_baton:WeaponBaton = null;

var half_beat_line_parent_width:float = 0.0;
var active_pulse_tween:Tween = null;
var notes_pool:Array[BatonMusicNote] = [];
var active_notes:Array[BatonMusicNote] = [];

func _ready() -> void:
	half_beat_line_parent_width = beat_lines_parent.size.x / 2.0;
	init_pool();

func update_hud(dt:float):
	var beat_ratio:float = weapon_baton.get_beat_ratio();
	update_beat_line(beat_line_l, half_beat_line_parent_width, 0.0, beat_ratio);
	update_beat_line(beat_line_r, beat_lines_parent.size.x, half_beat_line_parent_width, beat_ratio);

	for active_note in active_notes:
		if(active_note.position.x < -beat_lines_parent.size.x):
			active_notes.erase(active_note);
			return_note_to_pool(active_note);
		else:
			active_note.position.x -= weapon_baton.bpm * 1.35 * dt;

func update_beat_line(line:Line2D, start:float, goal:float, t:float):
	line.position.x = lerpf(start, goal, t);

func on_beat():
	weapon_baton.pulse(beat_line_l, Vector2.ONE, 0.2, 0.08);
	weapon_baton.pulse(beat_line_r, Vector2.ONE, 0.2, 0.08);
	pass;

func on_note(is_hit:bool, is_perfect:bool):
	var n:BatonMusicNote = spawn_note(is_hit, is_perfect);
	weapon_baton.pulse(n, Vector2.ONE, 1.0, 0.08);

func init_pool():
	for i in notes_pool_size:
		var n:BatonMusicNote = note.duplicate();
		notes_pool_parent.add_child(n);
		reset_note(n);
		notes_pool.push_back(n);

func reset_note(n:BatonMusicNote):
	n.position = Vector2.ZERO;
	n.visible = false;
	n.use_parent_material = true;

func spawn_note(is_hit:bool, is_perfect:bool) -> BatonMusicNote:
	var n:BatonMusicNote = get_note_from_pool();

	if(n == null): return;

	n.note.texture = weapon_baton.note_sprites[0] if is_hit else weapon_baton.note_sprites[1];

	if(is_perfect):
		n.note.self_modulate = weapon_baton.note_colors[2];
	else:
		n.note.self_modulate = weapon_baton.note_colors[0];

	n.position.y = get_random_line_y();
	n.z_index = 0 if !is_perfect else 1;

	active_notes.push_back(n);
	return n;

func get_note_from_pool() -> BatonMusicNote:
	if(notes_pool.size() == 0): return null;
	var n:BatonMusicNote = notes_pool.pop_back();
	n.visible = true;
	return n;

func return_note_to_pool(n:BatonMusicNote):
	reset_note(n);
	notes_pool.push_front(n);

func get_random_line_y() -> float:
	return lines_container.get_child(randi_range(0,lines_container.get_child_count() -1)).position.y;
