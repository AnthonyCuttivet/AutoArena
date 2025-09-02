class_name WeaponVortex extends Weapon

@export var min_rotating_dist:float = 100.0;
@export var max_rotating_dist:float = 500.0
@export var wave_speed:float = 100.0;
@export var rotating_bubbles:Array[Bubble];

var current_rot_dist:float = 0.0;
var t:float = 0.0;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);

func init(s:WeaponSettings, o:BattleBall):
	super.init(s, o);
	current_rot_dist = min_rotating_dist;
	arrange_rotating_bubbles();

func _process(delta: float) -> void:
	t += delta * wave_speed;
	current_rot_dist = lerp(min_rotating_dist, max_rotating_dist, pingpong(t, 1.0));
	for i in rotating_bubbles.size():
		rotating_bubbles[i].set_root_dist(current_rot_dist);

func init_scaling_stat():
	scaling_stat_value = rotation_speed;
	ball_owner.update_stat_text();

func scale_stat():
	# rotation_speed += stat_scale_value;

	init_scaling_stat();

func on_weapon_hit_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	scale_stat();
	pass;

# func get_custom_stat_format() -> String:
# 	return Utils.format_float(attack_speed * 3.0);

func arrange_rotating_bubbles():
	var angle:float = 360.0 / rotating_bubbles.size();
	for i in rotating_bubbles.size():
		rotating_bubbles[i].set_root_dist(min_rotating_dist);
		rotating_bubbles[i].global_rotation_degrees = angle * i;
