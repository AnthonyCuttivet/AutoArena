class_name WeaponVortex extends Weapon

@export var min_rotating_dist:float = 100.0;
@export var max_rotating_dist:float = 500.0;
@export var wave_speed:float = 100.0;
@export var clashes_dmg_boost:int = 1;
@export var hits_dmg_boost:int = 2;
@export var rotating_bubbles:Array[WeaponVortexBubble];
@export var bubbles_self_rot:Vector2;
@export var pop_delay:float = 0.1;
@export var repop_delay:float = 0.2;
@export var seq_repop_interval:float = 0.1;
@export var hit_bubble_sprite:Texture;
@export var hit_bubble_color:Color;
@export var sfx_popped_bubble:SFX;
@export var sfx_repop_bubble:SFX;

var current_rot_dist:float = 0.0;
var t:float = 0.0;
var popped_bubbles_count:int = 0;
var popped_bubbles_states:Dictionary[int,int];
var base_bubble_sprite:Texture = null;

func init(s:WeaponSettings, o:BattleBall):
	super.init(s, o);
	current_rot_dist = min_rotating_dist;
	base_bubble_sprite = sprite_2d.texture;
	setup_bubbles();

func _process(delta: float) -> void:
	if(ball_owner.stop): return;
	t += delta * wave_speed;
	current_rot_dist = lerp(min_rotating_dist, max_rotating_dist, pingpong(t, 1.0));
	for i in rotating_bubbles.size():
		rotating_bubbles[i].set_root_dist(current_rot_dist);

func init_scaling_stat():
	scaling_stat_value = damage;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	if(battleblock_mode):
		damage = 1 + Utils.get_claimed_blocks_amount(ball_owner);

	init_scaling_stat();

# func get_custom_stat_format() -> String:
# 	return Utils.format_float(attack_speed * 3.0);

func arrange_rotating_bubbles():
	var angle:float = 360.0 / rotating_bubbles.size();
	for i in rotating_bubbles.size():
		rotating_bubbles[i].set_root_dist(min_rotating_dist);
		rotating_bubbles[i].global_rotation_degrees = angle * i;

func setup_bubbles():
	arrange_rotating_bubbles();

	for i in rotating_bubbles.size():
		rotating_bubbles[i].init(settings, ball_owner);
		rotating_bubbles[i].init_bubble(randf_range(bubbles_self_rot.x, bubbles_self_rot.y), ball_owner, self);
		rotating_bubbles[i].fx_bubbles.self_modulate = ball_owner.color;

	reset_popped_bubbles();

func reset_popped_bubbles():
	popped_bubbles_count = 0;
	popped_bubbles_states[0] = 0;
	popped_bubbles_states[1] = 0;

func on_bubble_popped(is_hit:bool):
	popped_bubbles_count += 1;
	popped_bubbles_states[int(is_hit)] += 1;

	if(popped_bubbles_count == 3):
		# print("Popped Hits : " + str(popped_bubbles_states[1]) + " // Clashes : " + str(popped_bubbles_states[0]));
		if(popped_bubbles_states[1] >= 2 && !battleblock_mode):
			damage += hits_dmg_boost;

		scale_stat();
		get_tree().create_timer(repop_delay - (seq_repop_interval * 3)).timeout.connect(restore_bubbles);

func restore_bubbles():
	reset_popped_bubbles();
	for i in rotating_bubbles.size():
		get_tree().create_timer(seq_repop_interval * i).timeout.connect(restore_bubble.bind(i));

func restore_bubble(i:int):
	rotating_bubbles[i].damage = damage;
	rotating_bubbles[i].set_bubble_state(true, false);
	AudioManager.play_sfx(sfx_repop_bubble, "SFX");

func reset():
	restore_bubbles();
	damage = 1;
	super.reset();

func set_battleblock_modifiers():
	super.set_battleblock_modifiers();
	ball_owner.gravity_strength /= 3.5;
	ball_owner.relative_bounce_boost = 0.3;
	max_rotating_dist *= 2;

	settings.details = "";
