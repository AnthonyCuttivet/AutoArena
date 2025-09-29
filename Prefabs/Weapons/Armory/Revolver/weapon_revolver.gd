class_name WeaponRevolver extends Weapon

@export var max_bullets:int = 4;
@export var reload_duration:float = 1.6;
@export var bullets_textures:Array[Texture2D];
@export var bullets_trail_colors:Array[Color];
@export var bullets_damages:Array[int];
@export var bullets_weights:Array[float];
@export var bullets_weights_scale:Array[float];
@export var bullets_shoots_sfxs: Array[SFX];
@export var bullets_hit_sfxs: Array[SFX];
@export var bullets_ui:RevolverBullets;
@export var chance_to_be_absolute:float = 0.8;
@export var max_recoil:float = 1.0;

@export var sfx_reload_bullet:SFX;
@export var sfx_reload_barrel:SFX;

@onready var spawn: Node2D = $Sprite2D/Spawn

var remaining_bullets:int = 0;
var magazine:Array[int] = [0,0,0,0];
var cumulative_bullet_rarities:Array[float] = [];
var bullet_reload_timer:Timer;
var reload_over_timer:Timer;
var absolute_next_buller_timer:Timer;
var reloading:bool = false;
var custom_stat_str:String = "";
var absolute_next_bullet:float = 0.0;
var recoil_multiplier:float = 1.0;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_listened_event_received);

func init(s: WeaponSettings, o: BattleBall):
	super.init(s,o);

	update_cumulative_rarities();
	remaining_bullets = max_bullets;
	bullet_reload_timer = Utils.create_reusable_timer(self, reload_duration / max_bullets);
	reload_over_timer = Utils.create_reusable_timer(self, reload_duration / max_bullets);
	absolute_next_buller_timer = Utils.create_reusable_timer(self, 0.5);

	bullet_reload_timer.timeout.connect(reload_bullet);
	reload_over_timer.timeout.connect(reloading_finished);
	absolute_next_buller_timer.timeout.connect(set_absolute_next_bullet.bind(false));

func weapon_is_ready():
	ball_owner.stat_text.self_modulate = Color.WHITE;
	init_details();

func init_scaling_stat():
	scaling_stat_value = projectiles;
	ball_owner.update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	rotation_speed += 0.02;
	scale_rarities();
	init_scaling_stat();

func on_listened_event_received(id:int, to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	scale_stat();

	set_absolute_next_bullet(true);

	pass;

func shoot_projectile():
	if(reloading): return;
	if(remaining_bullets == 0):
		start_reloading();
		return;

	remaining_bullets -= 1;

	var bullet_id:int = magazine[remaining_bullets];
	var recoil:float = 1.0 + randf_range(0.0, max_recoil);

	custom_sfx_sound = bullets_shoots_sfxs[bullet_id];

	var bullet:ProjectileBullet = super.shoot_projectile();
	bullet.sprite_2d.texture = bullets_textures[bullet_id];
	bullet.set_trail_color(bullets_trail_colors[bullet_id]);
	bullet.custom_damage = bullets_damages[bullet_id];
	bullet.custom_hitstop = hitstop + (0.06 * (bullet_id));
	bullet.rand_shoot_elapsed_on_hit = true;
	bullet.trail.width += 2.0 * bullet_id;
	bullet.absolute = randf() <= chance_to_be_absolute;
	bullet.custom_hit_sfx = bullets_hit_sfxs[bullet_id];

	bullets_ui.consume_bullet(remaining_bullets);

	custom_rot_speed_multiplier = recoil;

func start_reloading():
	magazine.clear();
	reloading = true;
	bullet_reload_timer.start();
	rot_speed_multiplier -= 0.3;

	var t:Tween = create_tween();
	t.tween_property(sprite_2d, "rotation_degrees", -1440.0, 0.4).set_delay(reload_duration / max_bullets);
	t.parallel().tween_callback(func(): AudioManager.play_sfx(sfx_reload_barrel)).set_delay(0.2);
	t.tween_property(self, "custom_rot_speed_multiplier", 1.0 * sign(custom_rot_speed_multiplier), reload_duration / max_bullets).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);
	t.finished.connect(func(): sprite_2d.rotation_degrees = 0.0);

func reloading_finished():
	reloading = false;
	rot_speed_multiplier += 0.3;

func reload_bullet():
	var rarity:int = roll_bullet_rarity();
	magazine.push_back(rarity);

	AudioManager.play_sfx(sfx_reload_bullet, "SFX", 0.75 + (0.4 * rarity));
	bullets_ui.reload_bullet(remaining_bullets, bullets_textures[rarity]);
	remaining_bullets += 1;

	if(remaining_bullets == max_bullets):
		reload_over_timer.start();
	else:
		bullet_reload_timer.start();

func update_cumulative_rarities():
	cumulative_bullet_rarities.clear();

	var sum:float = 0.0;

	for i in bullets_weights:
		sum += i;
		cumulative_bullet_rarities.push_back(sum);

func roll_bullet_rarity() -> int:
	var rand:float = randf() * cumulative_bullet_rarities.back();
	for i in cumulative_bullet_rarities.size():
		if(rand <= cumulative_bullet_rarities[i]):
			return i;

	return 0;

func scale_rarities():
	for i in bullets_weights.size():
		bullets_weights[i] = bullets_weights[i] + bullets_weights_scale[i];

	update_cumulative_rarities();

func init_details():
	ball_owner.details_text.modulate = Color.WHITE;
	ball_owner.details_text.text = "[color=#" + ball_owner.color.to_html() + "] DMG : [/color]";

	for i in bullets_damages.size():
		ball_owner.details_text.text += "[color=#" + bullets_trail_colors[i].to_html() + "]" + str(bullets_damages[i]) + "[/color]";
		if(i < bullets_damages.size() - 1):
			ball_owner.details_text.text += "[color=#" + ball_owner.color.to_html() + "] / " + "[/color]";

	settings.details = ball_owner.details_text.text;

func get_custom_stat_format() -> String:
	custom_stat_str = "[/color]";
	for i in bullets_weights.size():
		custom_stat_str += "[color=#" + bullets_trail_colors[i].to_html() + "]" + (str(roundi((bullets_weights[i] * 100.0) / cumulative_bullet_rarities.back()))) + "[/color]";
		if(i < bullets_weights.size() - 1):
			custom_stat_str += "[color=#" + ball_owner.color.to_html() + "] / " + "[/color]";

	return custom_stat_str;

func set_absolute_next_bullet(s:bool):
	absolute_next_bullet = 1.0 if s else chance_to_be_absolute;

	if(s):
		absolute_next_buller_timer.start();
