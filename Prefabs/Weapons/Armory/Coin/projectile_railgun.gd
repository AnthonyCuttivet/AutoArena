class_name ProjectileRailgun extends Projectile

@export var railgun_length:float = 1000.0;
@export var railgun_length_duration:float = 0.2;
@export var railgun_width:float = 10.0;
@export var laser_thick_duration:float = 0.2;
@export var lifetime:float = 0.5;
@export var railgun_tick_time:float = 0.1;

@export var coin_projectile:Node2D;
@export var railgun_laser:Node2D;
@export var collider:CollisionShape2D;

var weapon_coin_owner:WeaponCoin = null;

var tick_damage_active:bool = false;
var tick_damage_elapsed:float = 0.0;
var tick_damage_duration:float = 0.0;
var has_scaled_stat:bool = false;

var pre_railgun_velocity:Vector2 = Vector2.ZERO;

func init(o:BattleBall, w:Weapon, s:float, p:int = -1, b:int = -1):
	super.init(o,w,s,p,b);

	weapon_coin_owner = w;

	railgun_width *= weapon_coin_owner.railgun_width_modifier;

	self.scale.x = 5.0;
	collider.shape.size.x = 0.0;
	coin_projectile.scale.y = 3.0;
	railgun_laser.scale.x = 0.0;

	AudioManager.play_sfx(weapon_coin_owner.sfx_railgun, "SFX");
	laser_tween();

func _physics_process(delta: float) -> void:
	if not tick_damage_active:
		return

	tick_damage_elapsed += delta
	if tick_damage_elapsed >= tick_damage_duration:
		tick_damage_elapsed = tick_damage_elapsed - tick_damage_duration;
		do_damage_tick()

func laser_tween():
	var t:Tween = create_tween();
	t.tween_property(coin_projectile, "scale:y", 0.0, 0.05).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT).set_delay(0.1);
	t.tween_property(railgun_laser, "scale:x", 1.0, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT);
	t.tween_callback(func(): EventBus.camera_trigger_shake.emit(40.0));
	t.tween_callback(func(): EventBus.set_chromatic_aberration.emit(5, 0.03));
	t.parallel().tween_property(self, "scale:y", railgun_width, 0.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT);
	t.parallel().tween_property(collider, "shape:size:x", 1000.0, 0.1);
	t.tween_callback(start_damaging);
	t.tween_property(self, "scale:y", 0.0, 0.05).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT).set_delay(weapon_coin_owner.railgun_duration);
	t.finished.connect(on_railgun_over);

func on_railgun_over():
	# print(Utils.pf() +  " Destroy");
	tick_damage_active = false;
	destroy();
	weapon_coin_owner.active_railgun = null;
	weapon_coin_owner.set_can_shoot(true);

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
