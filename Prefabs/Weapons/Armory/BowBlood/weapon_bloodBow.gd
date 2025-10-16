class_name WeaponBloodBow extends WeaponBow

@export var sfx_lifesteal_state:SFX;
@export var sfx_lifesteal_hit:SFX;
@export var sfx_lifesteal_heal:SFX;

var stop_lifesteal_after_salvo:bool = false;
var can_scale:bool = false;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);

func init(s:WeaponSettings, o:BattleBall) -> void:
	super.init(s,o);

func reset_shoots():
	super.reset_shoots();

	# if(stop_lifesteal_after_salvo):
	# 	update_lifesteal();
	# 	stop_lifesteal_after_salvo = false;

func init_scaling_stat():
	scaling_stat_value = projectiles;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	if(force || (lifesteal && lifesteal_active)):
		projectiles += stat_scale_value;
		init_scaling_stat();

func on_weapon_hit_received(id:int, slot_id:int, to:int, _is_projectile:bool):
	if(!is_valid_slot_it(id, slot_id)): return;

	if(battleblock_mode && ball_owner.main.get_ball_by_id(to) == null):
		return;

	if(lifesteal_active):
		# if(!stop_lifesteal_after_salvo):
		# 	stop_lifesteal_after_salvo = true;

		apply_lifesteal(damage, to);
		AudioManager.play_sfx(sfx_lifesteal_hit);
		get_tree().create_timer(0.3).timeout.connect(func(): AudioManager.play_sfx(sfx_lifesteal_heal));

		scale_stat();

	update_lifesteal();

func update_lifesteal():
	update_lifesteal_status();
	update_details();

	if(lifesteal_active):
		AudioManager.play_sfx(sfx_lifesteal_state);

func update_details():
	var s:String = "Heal + Scale in "+ str(lifesteal_ticked + 1) +" hits" if lifesteal_ticked > 0 else "[wave amp=25.0 freq=4 connected=1]Heal + Scale next hit[/wave]";
	settings.details = s;
	update_ui_details(settings.color if lifesteal_ticked > 0 else Color.DARK_RED, true);

func set_battleblock_modifiers():
	super.set_battleblock_modifiers();

	lifesteal = false;
