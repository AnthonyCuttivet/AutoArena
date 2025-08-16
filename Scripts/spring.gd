class_name Spring extends Resource

var frequency: float = 1.0;
var damping: float = 1.0;
var equilibrium: float = 0.0;
var active: bool;
var pos_vel: PosVel = null;
var params: DampedSpringMotionParams = null;

func _init(f: float, d: float, e: float) -> void:
	frequency = f;
	damping = d;
	equilibrium = e;
	pos_vel = PosVel.new();

func update(dt: float) -> float:
	if (!active): return equilibrium;
	params = SpringUtils.calc_damped_spring_motion_params(dt, frequency, damping);
	pos_vel = SpringUtils.update_damped_spring_motion(pos_vel, equilibrium, params);
	return pos_vel.pos;
