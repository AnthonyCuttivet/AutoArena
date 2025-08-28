class_name ProjectileTitanRock extends Projectile

@export var sfx_hit:SFX;

var max_hp:int = 4;
var hp:int = 0;

func init(o:BattleBall, s:float, p:int = -1, b:int = -1):
	super.init(o,s,p,b);
	hp = max_hp;

func _on_projectile_hitbox_area_entered(other: Area2D) -> void:
	if(!other is Hurtbox && !other is Hitbox): return;

	print("Contact with " + other.ball_owner.name);
	on_rock_hit();


func on_rock_hit():
	hp -= 1;
	sprite_2d.material.set_shader_parameter("sensitivity", (max_hp - hp + 1) * 0.1);

	if(hp == 0):
		weapon_owner.on_rock_destroyed(self);
