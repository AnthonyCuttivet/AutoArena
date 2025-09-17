class_name WeaponTraps extends Weapon

@export var trap_hit_total_duration:float = 0.4;
@export var combo_duration:float = 1.0;
@export var tx_neutral_trap:Texture;

@export var tx_armed_trap:Texture;
@export var tx_closed_trap:Texture;

@export var fx_trap_hit:PackedScene;
@export var fx_confettis: MultiFX;

@export var sfx_trap_trigger:SFX;
@export var sfx_trap_closed:SFX;

var combo_values:Dictionary[int,int];
var combo_remainings:Dictionary[int,float];
var best_combo:int = 0;

var hit_attack_base_texture:Texture;

var block_closing:bool = false;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_listened_event_received);

func _process(delta: float) -> void:
	for ball_id in combo_remainings:
		if(combo_remainings[ball_id] <= delta && combo_remainings[ball_id] > 0.0):
			clear_combo(ball_id);
		else:
			combo_remainings[ball_id] -= delta;

func init_scaling_stat():
	scaling_stat_value = damage;
	ball_owner.update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	damage += stat_scale_value;
	init_scaling_stat();

func on_trap_hit(other:BattleBall, hit_pos:Vector2, kb_dir:Vector2, hitstop:float):
	other.affect_health(-damage, ball_owner);
	other.start_hitstop(0.0, hitstop, kb_dir * knockback, true, true);
	other.hitflash(hitstop);
	other.hit_pos = hit_pos;

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), other.get_instance_id(), false);
	add_combo(other.get_instance_id());

	other.trail_2d.set_color(ball_owner.color);
	other.show_trail_for(combo_duration);
	other.afterimage.spawn_interval = 0.05;
	other.afterimage.set_custom_color(ball_owner.color);
	other.afterimage.draw_afterimages_for(combo_duration);

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, _hitbox_id:int, projectile_hit:bool = false) -> void:
	if(ball_owner.is_in_same_team(other)):
		return;

	if(ball_owner.hitstop_remaining > 0.0):
		return;

	var kb_dist:float = knockback + other.linear_velocity.length() if !other.is_boss else 0.0;
	var kb:Vector2 = (other.global_position - ball_owner.global_position).normalized() * kb_dist;
	var h:float = hitstop;

	if(projectile_hit):
		kb = (hit_pos - ball_owner.global_position).normalized() * kb_dist;

	if(!other.silent_on_hit):
		AudioManager.play_sfx(settings.sfx_hit, "SFX");

	other.affect_health(-damage, ball_owner);

	if(!projectile_hit):
		ball_owner.start_hitstop(0.0, h);

	other.start_hitstop(0.0, h, kb);
	other.hitflash(hitstop);
	other.hit_pos = hit_pos;

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), other.get_instance_id(), projectile_hit);
	pass;

func on_listened_event_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	pass;

func trap_hit_fxs(pos:Vector2):
	var fx: GPUParticles2D = fx_trap_hit.instantiate();
	ball_owner.main.add_child(fx);
	fx.position = Vector2.ZERO;
	fx.global_position = pos
	fx.scale *= 1.5;
	fx.finished.connect(fx.queue_free);
	fx.emitting = true;

func add_combo(ball_id:int) -> int:
	if(!combo_values.has(ball_id)):
		combo_values[ball_id] = 0;
		combo_remainings[ball_id] = 0.0;

	combo_values[ball_id] += 1;
	combo_remainings[ball_id] = combo_duration;

	# print(Utils.pf() + " Combo on " + str(ball_id) +  " : " + str(combo_values[ball_id]));

	if(combo_values[ball_id] > best_combo):
		on_best_combo(combo_values[ball_id]);

	return combo_values[ball_id];

func clear_combo(ball_id:int):
	combo_values[ball_id] = 0;
	combo_remainings[ball_id] = 0.0;
	# print(Utils.pf() + " Combo RESET");

func on_best_combo(v:int):
	best_combo = v;
	scale_stat();
	fx_confettis.emit();

func reset():
	super.reset();

func set_battleblock_modifiers():
	super.set_battleblock_modifiers();

	ball_owner.gravity_strength /= 3.5;
	ball_owner.relative_bounce_boost = 0.3;
