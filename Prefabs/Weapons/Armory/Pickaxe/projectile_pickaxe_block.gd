class_name ProjectilePickaxeBlock extends Projectile

@export var wall: StaticBody2D;

@onready var healthbar: Node2D = $Sprite2D/Health

var max_hp:int = 3;
var hp:int = 0;
var weapon_pickaxe:WeaponPickaxe = null;

func init(o:BattleBall, s:float, p:int = -1, b:int = -1):
	super.init(o,s,p,b);
	hp = max_hp;


func _on_weapon_hitbox_area_entered(other: Area2D) -> void:
	if(!other is Hurtbox && !other is Hitbox): return;

	if(other is Hitbox):
		on_block_hit(other);

func on_block_hit(other:Area2D):
	if(hp == 1):
		weapon_pickaxe.ball_owner.main.spawn_fx_block_destroyed(self.global_position, 1.0, sprite_2d.texture);
		destroy();
		weapon_pickaxe.scale_stat();
		weapon_pickaxe.spawn_block();
		pass;
	else:
		other.weapon.on_weapon_clash(self, self.global_position, false, false, true);
		hit_health();

func on_block_death():
	get_tree().get_current_scene().global_hitstop(0.01, 0.1);
	EventBus.camera_trigger_shake.emit(weapon_pickaxe.block_death_shake);
	AudioManager.play_sfx(weapon_pickaxe.sfx_block_death, "SFX");
	queue_free();

func set_state(s:bool):
	wall.collision_layer = 1 if s else 16;
	hitbox.monitoring = s;
	hitbox.monitorable = s;

func hit_health() -> bool:
	hp -= 1;
	healthbar.get_child(hp).self_modulate = Color(0.3,0.3,0.3,1);

	return hp == 0;
