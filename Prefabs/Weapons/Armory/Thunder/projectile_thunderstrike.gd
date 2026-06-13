class_name ProjectileThunderStrike extends Projectile

@export var thunderstrike_hitbox: CollisionShape2D
@export var thunderstrike_line: Line2D

var parents:Array[Projectile] = [];

func on_hurtbox_hit(other:BattleBall):
	super.on_hurtbox_hit(other);
	
	for p:Projectile in parents:
		p.self_destruct_remaining = self.destroy_on_hit_delay;
