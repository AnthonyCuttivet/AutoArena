class_name Projectile extends Node2D

@export var speed:float = 0.0;
@export var gravity_force:float = 0.0;
@export var max_gravity:float = 1.0;
@export var pierce_count:int = 0;
@export var bounce_count:int = 0;
@export var bounciness:float = 1.0;
@export var rotation_speed:float = 0.0;
@export var local_rotation:bool = false;
@export var absolute:bool = false;
@export var hitbox:ProjectileHitbox;
@export var destroy_on_hit_delay:float = 0.0;
@export var ball_owner:BattleBall;
@export var debug_destroy:bool = false;
@export var sprite_2d: Sprite2D;

@onready var raycast: RayCast2D = $RayCast2D

var custom_damage:int = -1;
var custom_hitstop:float = -1.0;
var weapon_owner:Weapon;
var velocity: Vector2 = Vector2.ZERO;
var self_destruct_remaining:float = 0.0;
var rand_shoot_elapsed_on_hit:bool = false;
var custom_hit_sfx:SFX;
var accumulated_gravity:float = 0.0;
var multihit_delay:float = 0.0;
var destruction_delay:float = 0.05;
var always_clash:bool = false;

func init(o:BattleBall, w:Weapon, s:float, p:int = -1, b:int = -1):
	ball_owner = o;
	weapon_owner = w;

	if(s != -1.0):
		speed = s;

	if(p != -1):
		pierce_count = p;

	if(b != -1):
		bounce_count = b;

	velocity = transform.x * speed;
	hitbox.ball_owner = o;
	hitbox.weapon = w;
	hitbox.projectile = self;

func _physics_process(delta: float) -> void:
	if(accumulated_gravity < max_gravity):
		accumulated_gravity = clamp(accumulated_gravity +  gravity_force, 0.0, max_gravity);

	velocity += accumulated_gravity * -ball_owner.transform.x;
	global_position += velocity * delta;

	if(local_rotation):
		sprite_2d.rotation_degrees += rotation_speed * delta;
	else:
		global_rotation_degrees += rotation_speed * delta;

	if(self_destruct_remaining > 0.0):
		self_destruct_remaining = clamp(self_destruct_remaining - delta, 0.0, 100.0);
		if(self_destruct_remaining == 0.0):
			destroy(0);

func set_speed(s:float):
	speed = s;
	velocity = transform.x * speed;

func _on_projectile_hitbox_area_entered(other: Area2D) -> void:
	if(other is Hurtbox && other.ball_owner != ball_owner && other.ball_owner.team != ball_owner.team):
		on_hurtbox_hit(other.ball_owner);
		if(weapon_owner.custom_sfx):
			if(weapon_owner.get("sfx_hit") != null):
				AudioManager.play_sfx(weapon_owner.sfx_hit, "SFX");
			else:
				AudioManager.play_sfx(weapon_owner.settings.sfx_hit, "SFX");
		pass;

	elif(other is Hitbox && (always_clash || (other.ball_owner != ball_owner && other.ball_owner.team != ball_owner.team))):
		if(absolute):
			if(other.ball_owner.weapon_settings.independent_weapon):
				other.weapon.on_weapon_clash(ball_owner, other.global_position, true);
			return;

		if(other.ball_owner.weapon_settings.independent_weapon):
			other.weapon.on_weapon_clash(ball_owner, other.global_position, true);
		else:
			other.weapon.on_weapon_clash(ball_owner, other.global_position, true);

		velocity = velocity.rotated(deg_to_rad(randf_range(90,270)));
		self.rotation = velocity.angle();

func _on_projectile_hitbox_body_entered(other: Node2D) -> void:
	if(absolute) : return;

	if(other.is_in_group("WALL")):
		bounce_count -= 1;
		if(bounce_count >= 0):
			accumulated_gravity = 0.0;
			if(raycast.get_collision_normal() != Vector2.ZERO):
				velocity = velocity.bounce(raycast.get_collision_normal()) * bounciness;
				if(velocity == Vector2.ZERO):
					destroy(1);
				self.rotation = velocity.angle();

	if(other.is_in_group("DEADZONE")):
		destroy(2);
		return;

func on_hurtbox_hit(other:BattleBall):
	if(other != null):
		weapon_owner.on_weapon_hit(other, self.global_position, hitbox.get_instance_id(), self);
		on_hit_effect(other);

	pierce_count -= 1;
	if(pierce_count < 0):
		destroy(3);

	if(destroy_on_hit_delay > 0.0 && self_destruct_remaining == 0.0):
		self_destruct_remaining = destroy_on_hit_delay;

	if(rand_shoot_elapsed_on_hit):
		ball_owner.weapon.shoot_speed_elapsed = (1.0 / ball_owner.weapon.shoot_speed) * randf_range(0.7,0.85);


func destroy(source:int = 0):
	if(debug_destroy):
		match source:
			0 : print("[P DESTROYED] 0 : Self-Destruct");
			1 : print("[P DESTROYED] 1 : Wall collision with no velocity");
			2 : print("[P DESTROYED] 2 : Deadzone");
			3 : print("[P DESTROYED] 3 : Hit with no pierce remaining");

	on_destroy_effect();
	get_tree().create_timer(destruction_delay).timeout.connect(queue_free);
	# queue_free();

func on_hit_effect(other:BattleBall):
	pass;

func on_destroy_effect():
	pass;
