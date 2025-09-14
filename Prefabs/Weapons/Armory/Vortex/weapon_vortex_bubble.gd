class_name WeaponVortexBubble extends Weapon

@export var rot_speed:float = 50.0;

@onready var r: Node2D = $Root

@onready var weapon_hitbox: Hitbox = $Root/Sprite2D/WeaponHitbox;
@onready var fx_bubbles: GPUParticles2D = $Root/FXBubbles;

var weapon_vortex:WeaponVortex = null;
var popped:bool = false;

func _process(delta: float) -> void:
	r.rotate(deg_to_rad(rot_speed*delta));

func set_root_dist(v:float):
	r.position.x = v;

func init_bubble(rspeed:float, o:BattleBall, w:WeaponVortex):
	rot_speed = rspeed;
	ball_owner = o;
	weapon_hitbox.weapon = self;
	weapon_vortex = w;

func on_weapon_hit(other:BattleBall, hit_pos:Vector2, _hitbox_id:int, projectile_hit:bool = false) -> void:
	if(other.is_invincible()):
		# print(other.name + " is INVINCIBLE");
		return;

	if(ball_owner.is_in_same_team(other)):
		return;

	if(!custom_sfx && !other.silent_on_hit):
		AudioManager.play_sfx(settings.sfx_hit, "SFX");

	pop_bubble(true);

	var d:int = get_custom_damage_value() if custom_damage else damage;

	var kb_dist:float = knockback + other.linear_velocity.length() if !other.knockback_immune else 0.0;

	var kb:Vector2 = (other.global_position - ball_owner.global_position).normalized() * kb_dist;

	if(projectile_hit):
		kb = (hit_pos - ball_owner.global_position).normalized() * kb_dist;

	other.affect_health(-d, ball_owner);

	if(!projectile_hit):
		ball_owner.start_hitstop(0.01, hitstop);
	else:
		if(projectile_self_hitstop):
			ball_owner.start_hitstop(0.0, hitstop);

	other.start_hitstop(0.0, hitstop, kb);
	other.hitflash(hitstop);
	other.hit_pos = hit_pos;

	EventBus.ball_weapon_hit.emit(ball_owner.get_instance_id(), other.get_instance_id(), projectile_hit);
	pass;

func on_weapon_clash(other:Node2D, clash_pos:Vector2, projectile_hit:bool = false, silent:bool = false):
	if(other == null): return;

	if(!silent):
		AudioManager.play_sfx(settings.sfx_clash, "SFX");

	pop_bubble(false);

	var kb:Vector2 = Vector2.ZERO;

	# if(!projectile_hit):
	# 	kb = (ball_owner.global_position - other.global_position).normalized() * ball_owner.linear_velocity.length() * 1.5;
	# 	reverse_rotation();

	ball_owner.start_hitstop_clash(0.0, 0.15, kb, other);

	EventBus.ball_weapon_clash.emit(ball_owner.get_instance_id(), clash_pos, silent);
	pass;

func pop_bubble(is_hit:bool):
	get_tree().create_timer(weapon_vortex.pop_delay).timeout.connect(set_bubble_state.bind(false, is_hit));

func set_bubble_state(s:bool, is_hit:bool):
	weapon_hitbox.collider.set_deferred("disabled", !s);

	if(!s && !popped):
		if(is_hit):
			sprite_2d.texture = weapon_vortex.hit_bubble_sprite;
			fx_bubbles.self_modulate = weapon_vortex.hit_bubble_color;
		else:
			sprite_2d.self_modulate = Color.GRAY;
			fx_bubbles.self_modulate = Color.GRAY;

		sprite_2d.self_modulate.a = 0.3;
		weapon_vortex.on_bubble_popped(is_hit);
		AudioManager.play_sfx(weapon_vortex.sfx_popped_bubble, "SFX");
	else:
		sprite_2d.texture = weapon_vortex.base_bubble_sprite;
		sprite_2d.self_modulate = Color.WHITE;
		sprite_2d.self_modulate.a = 1.0;
		fx_bubbles.self_modulate = ball_owner.color;

	popped = !s;
