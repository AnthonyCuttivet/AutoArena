class_name WeaponSneakers extends Weapon

@onready var sprite_parent: Node2D = $Sprite2D/SpriteParent

var dmg:float = 1.0;

func _init() -> void:
	EventBus.ball_weapon_hit.connect(on_weapon_hit_received);
	EventBus.ball_weapon_clash.connect(on_weapon_clash_received);

func init_scaling_stat():
	scaling_stat_value = damage;
	ball_owner.update_stat_text();

func scale_stat(force:bool = false):
	if(no_stat_scale && !force): return;
	dmg += stat_scale_value;
	damage = int(dmg);
	knockback += 200.0;
	init_scaling_stat();

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, _hitbox_id:int, projectile_hit:bool = false) -> void:
	if(ball_owner.is_in_same_team(other)):
		return;

	if(!other.silent_on_hit):
		AudioManager.play_sfx(settings.sfx_hit, "SFX");

	var d:int = get_custom_damage_value() if custom_damage else damage;

	var kb_dist:float = knockback + other.linear_velocity.length() if !other.knockback_immune else 0.0;

	var kb:Vector2 = Vector2.LEFT * kb_dist;

	if(projectile_hit):
		kb = (hit_pos - ball_owner.global_position).normalized() * kb_dist;

	ball_owner.start_hitstop(0.0, hitstop);
	other.start_hitstop(0.0, hitstop, kb);
	on_hit_animation();
	get_tree().create_timer(0.15).timeout.connect(on_weapon_hit_delayed.bind(d, other, kb, hit_pos));
	pass;

func on_weapon_hit_delayed(d:int, other:BattleBall, kb:Vector2, hit_pos:Vector2):
	other.affect_health(-d, ball_owner);
	ball_owner.start_hitstop(0.0, 0.125);
	other.start_hitstop(0.0, 0.125, kb, true);
	other.hitflash(hitstop);
	other.hit_pos = hit_pos;
	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), other.get_instance_id(), false);

func on_weapon_hit_received(id:int, _to:int, _is_projectile:bool):
	if(id != ball_owner.get_instance_id()): return;
	scale_stat();
	pass;

func on_weapon_clash_received(id:int, _clash_pos:Vector2, _silent:bool):
	if(id != ball_owner.get_instance_id()): return;
	on_clash_animation();
	pass;

func on_hit_animation():
	var t:Tween = create_tween();
	t.tween_property(sprite_parent, "scale:y", 2.5, 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_delay(0.15);
	t.parallel().tween_property(sprite_parent, "position:y", 50.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);
	t.tween_property(sprite_parent, "scale:y", 1.0, 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT);
	t.parallel().tween_property(sprite_parent, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);

func on_clash_animation():
	var t:Tween = create_tween();
	t.tween_property(sprite_parent, "scale", Vector2.ONE * 1.5, 0.1).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT);
	t.tween_property(sprite_parent, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT);


func set_battleblock_modifiers():
	super.set_battleblock_modifiers();
	ball_owner.gravity_strength /= 5.0;
	ball_owner.relative_bounce_boost = 0.5;
