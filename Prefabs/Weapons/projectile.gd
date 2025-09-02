class_name Projectile extends Node2D

@export var speed:float = 0.0;
@export var pierce_count:int = 0;
@export var bounce_count:int = 0;
@export var rotation_speed:float = 0.0;
@export var absolute:bool = false;
@export var hitbox:Area2D;
@export var destroy_on_hit_delay:float = 0.0;
@export var ball_owner:BattleBall;
@export var debug_destroy:bool = false;

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var raycast: RayCast2D = $RayCast2D

var custom_damage:int = -1;
var weapon_owner:Weapon;
var velocity: Vector2 = Vector2.ZERO;
var self_destruct_remaining:float = 0.0;

func init(o:BattleBall, s:float, p:int = -1, b:int = -1):
	ball_owner = o;

	if(s != -1.0):
		speed = s;

	if(p != -1):
		pierce_count = p;

	if(b != -1):
		bounce_count = b;

	velocity = transform.x * speed;

func _physics_process(delta: float) -> void:
	global_position += velocity * delta;
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
		# if(ball_owner.weapon_settings.name == "BOW"):
		# 	print(Utils.pf() + "")
		on_hurtbox_hit(other.ball_owner);
		if(weapon_owner.custom_sfx):
			AudioManager.play_sfx(weapon_owner.sfx_hit, "SFX");
		pass;

	elif(other is Hitbox && other.ball_owner != null && other.ball_owner != ball_owner && other.ball_owner.team != ball_owner.team):
		if(absolute) : return;
		other.ball_owner.weapon.on_weapon_clash(other.ball_owner, true);
		velocity = velocity.rotated(deg_to_rad(randf_range(90,270)));
		self.rotation = velocity.angle();

func _on_projectile_hitbox_body_entered(other: Node2D) -> void:
	if(absolute) : return;

	if(other.is_in_group("WALL")):
		bounce_count -= 1;
		if(bounce_count >= 0):
			if(raycast.get_collision_normal() != Vector2.ZERO):
				velocity = velocity.bounce(raycast.get_collision_normal());
				if(velocity == Vector2.ZERO):
					destroy(1);
				self.rotation = velocity.angle();

	if(other.is_in_group("DEADZONE")):
		destroy(2);
		return;

func on_hurtbox_hit(other:BattleBall):
	ball_owner.weapon.on_weapon_hit(other, self.global_position, hitbox.get_instance_id(), true);
	pierce_count -= 1;
	if(pierce_count < 0):
		destroy(3);

	if(destroy_on_hit_delay > 0.0 && self_destruct_remaining == 0.0):
		self_destruct_remaining = destroy_on_hit_delay;

func destroy(source:int = 0):
	if(debug_destroy):
		match source:
			0 : print("[P DESTROYED] 0 : Self-Destruct");
			1 : print("[P DESTROYED] 1 : Wall collision with no velocity");
			#2 : print("[P DESTROYED] 2 : Deadzone");
			3 : print("[P DESTROYED] 3 : Hit with no pierce remaining");

	on_destroy_effect();
	queue_free();

func on_hit_effect():
	pass;

func on_destroy_effect():
	pass;
