class_name ProjectileTitanShard extends Projectile

@export var sfx_hit:SFX;

func init(o:BattleBall, s:float, p:int = -1, b:int = -1):
	super.init(o,s,p,b);

func _on_projectile_hitbox_area_entered(other: Area2D) -> void:
	if(!other is Hurtbox && !other is Hitbox): return;
