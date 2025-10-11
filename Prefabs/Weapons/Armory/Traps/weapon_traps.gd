class_name WeaponTraps extends Weapon

@export var trap_hit_total_duration:float = 0.4;
@export var tx_neutral_trap:Texture;

@export var tx_armed_trap:Texture;
@export var tx_closed_trap:Texture;

@export var fx_trap_hit:PackedScene;
@export var fx_confettis: MultiFX;

@export var combo_color:Color;

@export var sfx_best_combo:SFX;
@export var sfx_trap_open:SFX;
@export var sfx_trap_armed:SFX;
@export var sfx_trap_crunch:SFX;
@export var sfx_trap_closed:SFX;
@export var sfx_trap_broken:SFX;
@export var sfx_trap_trigger:SFX;

var combo_remainings:Dictionary[int,float];
var best_combo:int = 0;

var hit_attack_base_texture:Texture;

var block_closing:bool = false;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_listened_event_received);

func _process(delta: float) -> void:
	for ball_id in combo_remainings:
		# if(combo_remainings[ball_id] <= delta && combo_remainings[ball_id] > 0.0):
		# 	clear_combo(ball_id);
		# else:
		combo_remainings[ball_id] -= delta;

func init_scaling_stat():
	scaling_stat_value = damage;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	damage += stat_scale_value;
	init_scaling_stat();

func on_trap_hit(other:BattleBall, hit_pos:Vector2, kb_dir:Vector2, h:float):
	other.affect_health(-damage, ball_owner, weapon_slot_id);
	other.start_hitstop(0.0, h, kb_dir * knockback, true, true);
	other.hitflash(h);
	other.hit_pos = hit_pos;

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), other.get_instance_id(), false);
	add_combo(other.get_instance_id(), hit_pos);

	other.trail_2d.set_color(ball_owner.color);
	other.show_trail_for(ball_owner.max_combo_duration);
	other.afterimage.spawn_interval = 0.05;
	other.afterimage.set_custom_color(ball_owner.color);
	other.afterimage.draw_afterimages_for(ball_owner.max_combo_duration);

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, _hitbox_id:int, projectile_hit:Projectile = null) -> void:
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

	other.affect_health(-damage, ball_owner, weapon_slot_id);

	if(!projectile_hit):
		ball_owner.start_hitstop(0.0, h);

	other.start_hitstop(0.0, h, kb);
	other.hitflash(hitstop);
	other.hit_pos = hit_pos;

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), other.get_instance_id(), projectile_hit != null);
	pass;

func trap_hit_fxs(pos:Vector2):
	for i in 5:
		ball_owner.main.spawn_fx(fx_trap_hit, pos, 0.0);

func add_combo(ball_id:int, hit_pos:Vector2):
	if(!combo_remainings.has(ball_id)):
		combo_remainings[ball_id] = 0.0;

	combo_remainings[ball_id] = ball_owner.max_combo_duration;

	if(best_combo == 0): # Because the first hit deals no damage, so no event for "damaged"
		ball_owner.add_combo(ball_owner.main.get_ball_by_id(ball_id), weapon_slot_id);

	# update_details_combo(combo_values[ball_id]);

	if(ball_owner.current_combo > best_combo):
		on_best_combo(ball_owner.current_combo, hit_pos);

func clear_combo(ball_id:int):
	combo_remainings[ball_id] = 0.0;
	# update_details_combo(0);
	# print(Utils.pf() + " Combo RESET");

func is_in_combo(ball_id) -> bool:
	return combo_remainings.has(ball_id) && combo_remainings[ball_id] > 0.0;

func on_best_combo(v:int, hit_pos):
	best_combo = v;
	scale_stat();
	fx_confettis.global_position = hit_pos;
	fx_confettis.emit();
	AudioManager.play_sfx(sfx_best_combo);

func update_details_combo(combo:int):
	if(combo == 0):
		settings.details = "";
	else:
		var h:String = get_combo_text(combo);
		var w:String = "[wave amp=" + str(combo * 25.0) + "freq=" + str(combo * 15.0) + "]";
		settings.details = w + "[color=" + combo_color.to_html() + "][b][i]" + str(combo) + " [/i][/b][/color]" + h + "[/wave]";

	update_ui_details(Color.WHITE, true);

func get_combo_text(combo:int) -> String:
	return "[color=#95DE03]h[/color][color=#85DB19]i[/color][color=#76D82F]t[/color]" + ("[color=#67D545]S[/color]" if combo > 1 else "") + " [color=#48CF72]c[/color][color=#39CC88]o[/color][color=#29C99E]m[/color][color=#26C1A0]b[/color][color=#23B9A2]o[/color] [color=#1CAAA6]![/color][color=#19A2A8]![/color][color=#169AAA]![/color]"

func reset():
	super.reset();

func set_battleblock_modifiers():
	super.set_battleblock_modifiers();

	ball_owner.gravity_strength /= 3.5;
	ball_owner.relative_bounce_boost = 0.3;
