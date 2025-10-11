class_name HydraTournamentSelector extends RichTextLabel

@export var main: Main;
@export var teams: Array[HydraTournamentTeamLine];
@export var team_p1s:Array[Enums.WEAPONS];
@export var team_p2s:Array[Enums.WEAPONS];
@export var team_names:Array[String];
@export var team_colors:Array[Color];
@export var single_sprites:Dictionary[Enums.WEAPONS, TextureRect];
@export var start_delay:float = 8.0;
@export var announcer_ve:Array[SFX];
@export var delays:Array[float];

func _ready() -> void:
	get_tree().create_timer(3.5).timeout.connect(aled);
	get_tree().create_timer(4.0).timeout.connect(aled_0);
	
	var total_delay:float = 0.0;
	
	for i in teams.size():
		total_delay += delays[i];
		teams[i].fill_line(team_names[i], team_colors[i], main.all_weapons[team_p1s[i]], main.all_weapons[team_p2s[i]], start_delay + total_delay);
		tween_single_sprites(team_p1s[i], team_p2s[i], start_delay + total_delay, i+1);

	get_tree().create_timer(43.0).timeout.connect(aled_1);
	get_tree().create_timer(56.0).timeout.connect(aled_2);

func tween_single_sprites(p1:Enums.WEAPONS, p2:Enums.WEAPONS, delay:float, i:int):
	var t:Tween = create_tween();
	t.tween_callback(func(): AudioManager.play_sfx(announcer_ve[i], "321GO")).set_delay(delay);
	t.parallel().tween_property(single_sprites[p1], "self_modulate", Color.DIM_GRAY, 0.2).set_delay(delay);
	t.parallel().tween_property(single_sprites[p1], "self_modulate:a", 0.3, 0.2).set_delay(delay);
	t.parallel().tween_property(single_sprites[p2], "self_modulate", Color.DIM_GRAY, 0.2).set_delay(delay);
	t.parallel().tween_property(single_sprites[p2], "self_modulate:a", 0.3, 0.2).set_delay(delay);

func aled():
	main.obs.send_command("StartRecord");

func aled_0():
	AudioManager.play_sfx(announcer_ve[0], "321GO");
	AudioManager.play_sound(main.bgm, -45.0, "BGM");

func aled_1():
	AudioManager.play_sfx(announcer_ve[12], "321GO");

func aled_2():
	main.show_next_patchnote_page();
	AudioManager.play_sfx(announcer_ve[13], "321GO");
