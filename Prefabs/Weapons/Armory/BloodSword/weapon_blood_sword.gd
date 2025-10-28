class_name WeaponBloodSword extends WeaponSword

@export var sfx_lifesteal_state:SFX;
@export var sfx_lifesteal_hit:SFX;
@export var sfx_lifesteal_heal:SFX;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);

func init_scaling_stat():
	scaling_stat_value = damage;
	update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	if(lifesteal && !lifesteal_active): return;
	damage += stat_scale_value;
	init_scaling_stat();

func on_weapon_hit_received(id:int, slot_id:int, to:int, _is_projectile:bool):
	if(!is_valid_slot_it(id, slot_id)): return;

	if(battleblock_mode && ball_owner.main.get_ball_by_id(to) == null):
		return;

	if(lifesteal_active):
		scale_stat();
		apply_lifesteal(damage, to);

	update_lifesteal_status();
	update_details();

	if(lifesteal_active):
		AudioManager.play_sfx(sfx_lifesteal_state);

	if(lifesteal_ticked == lifesteal_tick):
		AudioManager.play_sfx(sfx_lifesteal_hit);
		get_tree().create_timer(0.3).timeout.connect(func(): AudioManager.play_sfx(sfx_lifesteal_heal));

func update_details():
	var s:String = "Heal + Scale in "+ str(lifesteal_ticked + 1) +" hits" if lifesteal_ticked > 0 else "[wave amp=25.0 freq=4 connected=1]Heal + Scale next hit[/wave]";
	settings.details = s;
	update_ui_details(ball_owner.color if lifesteal_ticked > 0 else Color.DARK_RED, true);

func set_battleblock_modifiers():
	super.set_battleblock_modifiers();

	lifesteal = false;
