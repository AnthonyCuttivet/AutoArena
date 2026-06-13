class_name ProjectileBonesLaser extends Projectile

@export var railgun_length:float = 1000.0;
@export var railgun_length_duration:float = 0.2;
@export var railgun_width:float = 10.0;
@export var laser_thick_duration:float = 0.2;
@export var lifetime:float = 0.5;
@export var railgun_tick_time:float = 0.1; #0.04

@export var railgun_laser:Node2D;
@export var collider:CollisionShape2D;

@export var skull: Node2D;
@export var open_skull:Texture2D;

@onready var head: Sprite2D = $Skull/Head

var weapon_bones:WeaponBones = null;

var tick_damage_active:bool = false;
var tick_damage_elapsed:float = 0.0;
var tick_damage_duration:float = 0.0;
var has_scaled_stat:bool = false;

var pre_railgun_velocity:Vector2 = Vector2.ZERO;

func init(o:BattleBall, w:Weapon, s:float, p:int = -1, b:int = -1):
	super.init(o,w,s,p,b);

	weapon_bones = w;

	railgun_width *= weapon_bones.laser_width_modifier;

	sprite_2d.scale.x = 3.0;
	collider.shape.size.x = 0.0;
	railgun_laser.scale.x = 0.0;

	skull.scale *= 5.0;
	# skull.rotation_degrees = 90.0;

	# AudioManager.play_sfx(weapon_bones.sfx_railgun, "SFX");
	# laser_tween();
	move_tween();

func _physics_process(delta: float) -> void:
	if not tick_damage_active:
		return

	tick_damage_elapsed += delta
	if tick_damage_elapsed >= tick_damage_duration:
		tick_damage_elapsed = tick_damage_elapsed - tick_damage_duration;
		do_damage_tick()

func move_tween():
	var t:Tween = create_tween();
	t.parallel().tween_property(self, "global_position", weapon_bones.laser_final_pos, weapon_bones.laser_move_duration * 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT);
	t.parallel().tween_property(self, "rotation_degrees", weapon_bones.laser_final_rot, weapon_bones.laser_move_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT);
	t.finished.connect(laser_tween);

func laser_tween():
	head.texture = open_skull;

	var t:Tween = create_tween();
	t.tween_property(railgun_laser, "scale:x", 1.0, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT);
	t.tween_callback(func(): EventBus.camera_trigger_shake.emit(40.0));
	t.tween_callback(func(): EventBus.set_chromatic_aberration.emit(5, weapon_bones.laser_duration));
	t.parallel().tween_property(sprite_2d, "scale:y", railgun_width, 0.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT);
	t.parallel().tween_property(collider, "shape:size:x", 1000.0, 0.1);
	t.tween_callback(start_damaging);
	t.tween_property(sprite_2d, "scale:y", 0.0, 0.05).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT).set_delay(weapon_bones.laser_duration);
	t.parallel().tween_property(self, "global_position", global_position + (-global_transform.x * 200.0), weapon_bones.laser_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT);
	t.finished.connect(on_laser_over);

func on_laser_over():
	# print(Utils.pf() +  " Destroy");
	tick_damage_active = false;
	destroy();
	weapon_bones.active_laser = null;
	weapon_bones.set_can_shoot(true);

func start_damaging():
	# print(Utils.pf() + " Start damaging");
	tick_damage_duration = railgun_tick_time
	tick_damage_active = true;

func do_damage_tick() -> void:
	# print("DAMAGE TICK")
	collider.disabled = false
	call_deferred("disable_next_frame")

func disable_next_frame() -> void:
	await get_tree().process_frame  # wait one full frame
	collider.disabled = true
