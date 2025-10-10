class_name ProjectileTitanShard extends Projectile

@export var sfx_hit:SFX;

func init(o:BattleBall, w:Weapon, s:float, p:int = -1, b:int = -1):
	super.init(o,w,s,p,b);
