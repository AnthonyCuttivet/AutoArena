extends Node

signal match_setup();
signal match_started();
signal start_countdown();
signal ball_dead(id: int);
signal match_over(winner: int);
signal round_timeout();
signal ball_got_low_health(id: int);
signal set_chromatic_aberration(v: float, d:float);

signal play_sound(name: String);
signal play_player_sfx(player_id: int, name: String);
signal player_damaged(player_id: int, amount: int);
signal combo_changed(player_id: int);
signal health_changed(player_id: int, amount: int);
signal camera_trigger_shake(strength: float);

signal start_audio_fade_in(instance_id: int, fade_in: float);

signal stop_record();

signal ball_damaged(id:int, amount:int, from:int);
signal ball_lifesteal(from:int, to:int);
signal ball_weapon_hit(id:int, to:int, is_projectile:bool);
signal ball_weapon_clash(id:int, clash_pos:Vector2, silent:bool);
signal ball_update_stat(id:int);
signal ball_bounce(id:int);
signal ball_bounce_other_ball(id:int, other:int);
signal ball_bounce_battleblock(id:int, block:BattleBlock);
signal ball_shoot(id:int, projectile: Projectile);

signal block_hit(id:int, block:BattleBlock);
signal block_destroyed(id:int, block:BattleBlock);
signal ball_duel_scale(id:int);
signal ball_duel_winner(id:int);
