class_name ProjectileHitbox extends Area2D

@export var ball_owner:BattleBall;
@export var weapon:Weapon;
@export var projectile:Projectile;

func is_overlapping_target(t:BattleBall) -> bool:
	if(!monitoring): return false;
	for area in get_overlapping_areas():
		if(area is Hurtbox && area.ball_owner == t):
			print(area);
			return true;
	return false;
