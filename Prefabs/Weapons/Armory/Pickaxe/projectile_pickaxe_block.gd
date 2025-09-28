class_name ProjectilePickaxeBlock extends Projectile

@export var wall: StaticBody2D;
@export var upgrade:ColorRect;

@onready var healthbar: Node2D = $Sprite2D/Health
@onready var hurtbox: CollisionShape2D = $Sprite2D/WeaponHitbox/CollisionShape2D

var max_hp:int = 1;
var hp:int = 0;
var weapon_pickaxe:WeaponPickaxe = null;
var level:int = 0;
var is_upgrade:bool = false;

func init(o:BattleBall, s:float, p:int = -1, b:int = -1):
	super.init(o,s,p,b);
	hp = max_hp;

	on_spawn_tween();


func _on_weapon_hitbox_area_entered(other: Area2D) -> void:
	if(!other is Hurtbox && !other is Hitbox && !other is ProjectileHitbox): return;

	if(other is Hitbox || other is ProjectileHitbox || (other is Hurtbox && other.hurtbox_is_hitbox)):
		on_block_hit(other.ball_owner);

func on_block_hit(from:BattleBall):
	if(from != ball_owner && from.team == ball_owner.team): return;
	hit_health();
	weapon_pickaxe.on_block_destroyed(from, self);
	from.weapon.on_weapon_clash(self, self.global_position, false, false, true);

func set_state(s:bool):
	wall.collision_layer = 1 if s else 16;
	hitbox.monitoring = s;
	hitbox.monitorable = s;

func hit_health() -> bool:
	hp -= 1;
	healthbar.get_child(hp).self_modulate = Color(0.3,0.3,0.3,1);
	AudioManager.play_sfx(weapon_pickaxe.sfx_block_hit, "SFX");
	return hp == 0;

func on_spawn_tween():

	sprite_2d.scale = Vector2.ZERO;
	sprite_2d.position.y -= 500.0;

	var t:Tween = create_tween();
	t.tween_property(sprite_2d, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);
	t.tween_property(sprite_2d, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).set_delay(0.1);

	t.finished.connect(enable_hurtbox);
	t.finished.connect(func(): AudioManager.play_sfx(weapon_pickaxe.sfx_block_spawn, "SFX"));
	t.finished.connect(update_is_upgrade);

func enable_hurtbox():
	hurtbox.set_deferred("disabled", false);

func update_is_upgrade():
	upgrade.visible = is_upgrade;
