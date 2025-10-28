class_name WeaponBaton extends Weapon

@export var bpm:int = 100;
@export var beat_damage:float = 4.0;
@export var beat_damage_scale:float = 2.0;
@export var hud_prefab:PackedScene;
@export var hud_x_offset:float = 50.0;
@export var valid_beat:float = 0.2;
@export var note_colors:Array[Color];
@export var note_sprites:Array[Texture2D];
@export var fx_note_prefab:PackedScene;
@export var fx_pulse_prefab:PackedScene;
@export var fx_pulse_scale:float = 1.0;
@export var fx_confettis: MultiFX;
@export var sfx_perfect:SFX;
@export var sfxs_arpeggio:Array[AudioStreamMP3];
@export var sfx_arpeggio_volume:float = -30.0;
@export var arpeggio_reset_delay:float = 1.0;

@onready var fx_spawn_point: Node2D = $Sprite2D/FXSpawnPoint

var hud:BatonHUDBeat = null;
var beat_elapsed:float = 0.0;
var beat_interval:float = 0.0;
var arpeggio_index:int = 0;
var arpeggio_elapsed:float = 0.0;
var block_perfect:bool = false;
var last_note_perfect:bool = false;

func set_bpm(v:int):
	bpm = v;
	beat_interval = 60.0 / bpm;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);
	EventBus.ball_weapon_clash.connect(on_weapon_clash_received);

func _process(delta: float) -> void:
	beat_elapsed += delta;

	if(arpeggio_elapsed < arpeggio_reset_delay):
		arpeggio_elapsed += delta;
		if(arpeggio_elapsed >= arpeggio_reset_delay):
			arpeggio_index = 0;
			arpeggio_elapsed = 0.0;

	hud.update_hud(delta);

	if(beat_elapsed >= beat_interval):
		beat_elapsed -= beat_interval;
		on_beat();

func weapon_is_ready():
	stat_text.self_modulate = Color.WHITE;
	details_text.modulate = Color.WHITE;
	set_bpm(bpm);
	spawn_hud();

func spawn_hud():
	hud = hud_prefab.instantiate();
	hud.weapon_baton = self;
	ball_owner.main.add_child(hud);

	var pos_x:float = (hud_x_offset * 2.0) if ball_owner.team == 0 else 1080.0;
	hud.position = Vector2(pos_x - hud_x_offset, 1400);

func on_beat():
	hud.on_beat();
	pulse(ball_owner.root, ball_owner.root.scale, 0.15, 0.08);
	pulse(ui_sprite, Vector2.ONE, 0.1, 0.08);
	pulse_color(sprite_2d, note_colors[2], Color.WHITE, valid_beat * 2.0);
	pulse_color(ball_owner.active_sprite, note_colors[2], settings.color, valid_beat * 2.0);

func on_note(is_hit:bool):
	var perfect:bool = last_note_perfect;
	last_note_perfect = false;

	spawn_note_fx(is_hit, perfect);

	if(perfect):
		AudioManager.play_sfx(sfx_perfect);
		fx_confettis.emit();

	hud.on_note(is_hit, perfect);

func init_scaling_stat():
	scaling_stat_value = damage;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	if(lifesteal && !lifesteal_active): return;
	beat_damage += beat_damage_scale;
	init_scaling_stat();

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, _hitbox_id:int, projectile_hit:Projectile = null) -> void:
	if(ball_owner.is_in_same_team(other)):
		return;

	if(!other.silent_on_hit):
		AudioManager.play_sfx(settings.sfx_hit, "SFX");

	play_sfx_arpeggio();

	var perfect:bool = check_valid_beat();

	var d:int = int(beat_damage) if perfect else damage;
	var kb_dist:float = knockback + other.linear_velocity.length() if !other.knockback_immune else 0.0;
	var kb:Vector2 = (other.global_position - ball_owner.global_position).normalized() * kb_dist;
	var h:float = hitstop * 3.0 if perfect else hitstop;

	if(projectile_hit):
		kb = (hit_pos - ball_owner.global_position).normalized() * kb_dist;

	other.hit_pos = hit_pos;
	other.affect_health(-d, ball_owner, weapon_slot_id);

	if(!projectile_hit):
		ball_owner.start_hitstop(0.0, h);

	other.start_hitstop(0.0, h, kb);
	other.hitflash(hitstop);

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), weapon_slot_id, other.get_instance_id(), projectile_hit != null);
	pass;

func on_weapon_clash(other:Node2D, clash_pos:Vector2, projectile_hit:bool = false, silent:bool = false, force:bool = false):
	if(!silent):
		AudioManager.play_sfx(settings.sfx_clash, "SFX");

	var kb:Vector2 = Vector2.ZERO;

	play_sfx_arpeggio();

	if(!projectile_hit):
		kb = (ball_owner.position - other.position).normalized() * ball_owner.max_speed;
		reverse_rotation();

	if(check_valid_beat() && other.team != ball_owner.team):
		scale_stat();
		other.affect_health(-int(beat_damage), ball_owner, weapon_slot_id, false, true);

	ball_owner.start_hitstop_clash(0.0, 0.15, kb, other);
	EventBus.ball_weapon_clash.emit(ball_owner.get_instance_id(), weapon_slot_id, clash_pos, silent);
	pass;

func on_weapon_hit_received(id:int, slot_id:int, _to:int, _is_projectile:bool):
	if(!is_valid_slot_it(id, slot_id)): return;
	if(last_note_perfect):
		scale_stat();

	on_note(true);

func on_weapon_clash_received(id:int, slot_id:int, _clash_pos:Vector2, _silent:bool):
	if(!is_valid_slot_it(id, slot_id)): return;
	on_note(false);
	pass;

func get_beat_ratio() -> float:
	return clamp(beat_elapsed / beat_interval, 0.0, 1.0);

func check_valid_beat() -> bool:
	if(block_perfect): return false;

	var r:float = get_beat_ratio();
	var is_perfect:bool = r <= valid_beat || r + valid_beat >= 1.0;

	if(is_perfect):
		block_perfect = true;
		get_tree().create_timer(beat_interval / 2.0).timeout.connect(func(): block_perfect = false);

	last_note_perfect = is_perfect;

	return is_perfect;

func pulse(o:Node, b:Vector2, s:float, d:float):
	if(o == null): return;

	var t:Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);

	t.tween_property(o, "scale", b * (1.0 + s), d)
	t.tween_property(o, "scale", b, d * 0.6)

func pulse_color(node: Node, color: Color, base_color:Color, duration: float = 0.3):
	var t := node.create_tween()
	t.tween_property(node, "self_modulate", color, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(node, "self_modulate", base_color, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func play_sfx_arpeggio():
	AudioManager.play_sound(sfxs_arpeggio[arpeggio_index], sfx_arpeggio_volume, "SFX");

	if(arpeggio_index < sfxs_arpeggio.size() - 1):
		arpeggio_index += 1;

func spawn_note_fx(is_hit:bool, is_perfect:bool):
	var fx_note:GPUParticles2D = ball_owner.main.spawn_fx(fx_note_prefab, fx_spawn_point.global_position, deg_to_rad(randf_range(30.0,60.0)));

	if(is_perfect):
		fx_note.self_modulate = note_colors[2];
	else:
		fx_note.self_modulate = note_colors[0];

	fx_note.texture = note_sprites[0] if is_hit else note_sprites[1];

func get_custom_stat_format() -> String:
	return "♪ " + str(damage) + " ⬩[/color] [color=" + note_colors[2].to_html() + "]♪♫ " + ("%.0f" % beat_damage) + "[/color]";
