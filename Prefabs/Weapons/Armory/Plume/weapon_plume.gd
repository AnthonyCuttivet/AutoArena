class_name WeaponPlume extends Weapon

@export var max_feathers:int = 3;
@export var dmg_to_feather_conversion:int = 3;
@export var feather_move_duration:float = 1.0;
@export var recall_delay:float = 1.0;
@export var feather_recall_duration:float = 0.1;
@export var recall_self_hitstop_t:float = 0.1;
@export var recall_speed_multiplier:float = 2.0;
@export var recall_hitstop:float = 0.35;
@export var feather_sub_weapon_prefab:PackedScene;
@export var feather_sub_weapon_spread:float;
@export var feathers_gradient:Gradient;
@export var sfx_recall:SFX;
@export var sfx_recall_hit:SFX;

@onready var feathers_parent: Node2D = $Feathers

var recall_dmg:int = 1;
var recalling:bool = false;

var feathers:Array[ProjectilePlume];
var sub_weapons:Array[FeatherSubWeapon];

var current_shoot_speed:float = 0.0;
var base_feathers:int = 0;
var recall_dmg_bonus:int = 0;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_listened_event_received);
	base_feathers = max_feathers;

func init(s:WeaponSettings, o:BattleBall) -> void:
	super.init(s,o);

	for i in range(max_feathers):
		add_sub_weapon(i, i == max_feathers -1);

	current_shoot_speed = shoot_speed;

func _process(_delta: float) -> void:
	if(ball_owner.health <= 0 && feathers.size() > 0):
		for f in feathers:
			if(is_instance_valid(f)):
				f.queue_free();


func init_scaling_stat():
	scaling_stat_value = recall_dmg;
	ball_owner.update_stat_text();

func shoot_projectile():
	spawn_feather();

func scale_stat():
	recall_dmg += int(stat_scale_value);

	if(recall_dmg == dmg_to_feather_conversion + recall_dmg_bonus):
		max_feathers += 1;
		recall_dmg_bonus += 1;
		recall_dmg = 1 + recall_dmg_bonus;
		current_shoot_speed += 1.0;
		shoot_speed = current_shoot_speed;
		add_sub_weapon(max_feathers -1, true);

		settings.details = plume_details();
		ball_owner.update_ui_details(ball_owner.color, true);

	init_scaling_stat();

func on_listened_event_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	if(recalling):
		scale_stat();
	pass;

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, _hitbox_id:int, projectile_hit:bool = false) -> void:
	if(other.is_invincible()):
		# print(other.name + " is INVINCIBLE");
		return;

	if(ball_owner.is_in_same_team(other)):
		return;

	AudioManager.play_sfx(settings.sfx_hit if !recalling else sfx_recall_hit, "SFX");

	var d:int = recall_dmg if recalling else damage;
	var kb_dist:float = knockback + other.linear_velocity.length() if !other.knockback_immune else 0.0;
	var kb:Vector2 = (other.global_position - ball_owner.global_position).normalized() * kb_dist;
	var h:float = recall_hitstop if recalling else hitstop;

	if(projectile_hit):
		kb = (hit_pos - ball_owner.global_position).normalized() * kb_dist;

	other.affect_health(-d, ball_owner);

	if(!projectile_hit):
		ball_owner.start_hitstop(0.01, h);

	other.start_hitstop(0.0, h, kb);
	other.hitflash(hitstop);
	other.hit_pos = hit_pos;

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), other.get_instance_id(), projectile_hit);
	pass;

func add_sub_weapon(i:int, update_spread:bool = false):
	var sub_weapon:FeatherSubWeapon = feather_sub_weapon_prefab.instantiate();
	sub_weapon.weapon_hitbox.ball_owner = ball_owner;
	sub_weapon.weapon_hitbox.weapon = self;

	sub_weapons.push_back(sub_weapon);
	feathers_parent.add_child(sub_weapon);

	if(update_spread):
		Utils.arrange_in_fan(sub_weapons, Vector2.ZERO, 0.0, deg_to_rad(feather_sub_weapon_spread), 0.0);
		for s in sub_weapons.size():
			sub_weapons[s].sprite_2d.self_modulate = feathers_gradient.sample(s * (1.0 / (i + 1.0)));
			pass

	pass;

func spawn_feather():
	if(feathers.size() == max_feathers):
		recall_feathers();

		shoot_speed_elapsed = 0.0;
		shoot_speed = current_shoot_speed;
		return;

	toggle_sub_weapon(feathers.size(), false);

	if(feathers.size() == max_feathers - 1):
		shoot_speed_elapsed = 0.0;
		shoot_speed = recall_delay;

	var p:ProjectilePlume = Utils.shoot_projectile(settings.projectile_prefab, ball_owner, ball_owner.weapon_slot.global_rotation, self);
	p.scale *= ball_owner.weapon.projectile_scale;
	p.set_speed(projectile_speed);
	p.weapon_owner = self;
	p.move_duration = feather_move_duration;
	p.recall_duration = feather_recall_duration;
	p.plume_sprite_2D.self_modulate = sub_weapons[feathers.size()].sprite_2d.self_modulate;
	p.trail.set_color(p.plume_sprite_2D.self_modulate);
	p.trail.set_active(false);
	feathers.push_back(p);

	AudioManager.play_sfx(settings.sfx_shoot, "SFX");

func recall_feathers():
	recalling = true;
	get_tree().create_timer(feather_recall_duration).timeout.connect(on_recall_over);

	ball_owner.start_hitstop(recall_self_hitstop_t, feather_recall_duration * 2.0);
	ball_owner.block_weapon_rot = true;

	for feather in feathers:
		feather.recall();
		pass

	feathers.clear();

	AudioManager.play_sfx(sfx_recall, "SFX");
	pass;

func toggle_sub_weapon(i:int, s:bool):
	sub_weapons[i].visible = s;
	sub_weapons[i].set_process(s);
	sub_weapons[i].weapon_hitbox.monitorable = s;
	sub_weapons[i].weapon_hitbox.monitoring = s;

func on_recall_over():
	recalling = false;
	ball_owner.block_weapon_rot = false;

	for i in range(max_feathers):
		toggle_sub_weapon(i, true);
		feather_reappear_gamefeel(sub_weapons[i]);
		pass

func feather_reappear_gamefeel(f:FeatherSubWeapon):

	var tween:Tween = create_tween();
	f.sprite_2d.scale = Vector2.ZERO;
	f.sprite_2d.modulate.a = 0.0;

	tween.set_parallel(true);
	tween.tween_property(f.sprite_2d, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK);
	tween.tween_property(f.sprite_2d, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_IN_OUT);

func get_custom_stat_format() -> String:
	return str(recall_dmg) + " / " + str(dmg_to_feather_conversion + recall_dmg_bonus);

func plume_details() -> String:
	return str(dmg_to_feather_conversion + recall_dmg_bonus) + " DMG ⬗ +1 Feather";
