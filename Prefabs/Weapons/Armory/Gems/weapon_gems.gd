class_name WeaponGems extends Weapon

@export var dice_textures:Array[Texture];
@export var dice_values:Array[int];
@export var dice_rotations:Array[float];
@export var sfx_upgrade:SFX;
@export var sfx_dice_roll:SFX;
@export var sfx_hit:SFX;
@export var sfxs_hit_pitch:float;
@export var dice_upgrade_effect_duration:float = 1.0;
@export var dice_roll_duration:float = 0.25;
@export var max_roll_color:Color;
@export var roulette_colors:Array[Color];
@export var fx_confettis: MultiFX;
@export var levels_colors:Array[Color];
@export var cheat_first_hit:bool = true;

var dice_index:int = 0;
var dice_upgrade_effect_remaining:float = 0.0;
var dice_roll_remaining:float = 0.0;
var level_name_init:bool = false;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);

func init(s:WeaponSettings, o:BattleBall):
	super.init(s,o);

func _process(delta):
	if(ball_owner.main != null && !level_name_init):
		level_name_init = true;
		ball_owner.main.set_weapon_ui_name(ball_owner.get_instance_id(), Color.WHITE, get_name_and_level_str());

	if(dice_upgrade_effect_remaining > 0.0):
		dice_upgrade_effect_remaining -= delta;
		if(dice_upgrade_effect_remaining < 0.0):
			dice_upgrade_effect_remaining = 0.0;

	if(dice_roll_remaining > 0.0):
		dice_roll_remaining -= delta;
		if(dice_roll_remaining < 0.0):
			dice_roll_remaining = 0.0;
			init_scaling_stat();
	pass

func init_scaling_stat():
	scaling_stat_value = damage;
	ball_owner.update_stat_text();

func scale_stat():
	var r:int = get_dice_roll();
	AudioManager.play_sfx(sfx_dice_roll, "SFX");
	dice_roll_remaining += dice_roll_duration;

	if(r == dice_values[dice_index]):
		set_dice(dice_index+1);
		on_dice_upgrade();

	damage = r;
	init_scaling_stat();

func on_weapon_hit_received(id:int, to:int, is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	AudioManager.play_sfx(sfx_hit, "SFX", 1.0 + (dice_index * sfxs_hit_pitch));
	scale_stat();
	pass;

func get_dice_roll() -> int:
	if(dice_index == 0 && cheat_first_hit):
		return dice_values[0];
	return Scalings.random(dice_values[dice_index]);

func set_dice(i:int):
	dice_index = i;
	sprite_2d.texture = dice_textures[i];
	sprite_2d.rotation_degrees = dice_rotations[i];

func on_dice_upgrade():
	dice_upgrade_effect_remaining += dice_upgrade_effect_duration;
	AudioManager.play_sfx(sfx_upgrade, "SFX");
	ball_owner.main.set_weapon_ui_sprite(ball_owner.get_instance_id());
	fx_confettis.emit();
	ball_owner.main.set_weapon_ui_name(ball_owner.get_instance_id(), Color.WHITE, get_name_and_level_str());

func get_custom_stat_format() -> String:
	var dmg:String = str(damage);

	if(dice_upgrade_effect_remaining > 0.0):
		dmg = "[color=" + max_roll_color.to_html()+"]" + str(damage) + "[/color]";

	return "[wave amp=50.0 freq=" + (str(20) if dice_upgrade_effect_remaining > 0.0 else str(0)) + "]" + (get_roulette_str() if dice_roll_remaining > 0.0 else dmg) + "    ( 1~" + str(dice_values[dice_index]) + " )[/wave]";

func get_roulette_str() -> String:
	return "[wave amp=50.0 freq=25.0][color="+roulette_colors[0].to_html()+"]?[/color][color="+roulette_colors[1].to_html()+"]?[/color][color="+roulette_colors[2].to_html()+"]?[/color][/wave]";

func get_name_and_level_str() -> String:
	var amp:float = dice_index * 10.0;
	var c:String = levels_colors[dice_index].to_html();
	return " [color=" + ball_owner.color.to_html() + "]" + ball_owner.weapon_settings.name + "[/color] [wave amp=" + str(amp) + " freq=" + str(amp / 2.0) + "][color=" + c + "]LV." + str(dice_index) + "[/color][/wave] ";
