class_name Hitbox extends Area2D

@export var weapon:Weapon;
@export var collider:CollisionShape2D;
@export var unclashable:bool = false;

var ball_owner:BattleBall;
var target_cd:Dictionary[BattleBall, float];
var weapon_clash_cd:float = 0.2;
var weapon_clash_cd_elapsed:float = 0.0;
var ignored_targets:Dictionary[BattleBall, int] = {};

func init() -> void:
	weapon_clash_cd_elapsed = weapon_clash_cd;
	pass;

func _process(delta: float) -> void:

	for ball in target_cd:
		target_cd[ball] = max(0.0, target_cd[ball] - delta);
		if(is_overlapping_target(ball) && target_cd[ball] <= 0.0 && !is_clash_on_cd()):
			refresh_target_cd(ball);
			if(!ball.is_invincible()):
				weapon.on_weapon_hit(ball, ball_owner.global_position, self.get_instance_id());

	if(is_clash_on_cd()):
		weapon_clash_cd_elapsed += delta;

func _on_area_entered(other: Area2D) -> void:
	if(other == null && other.ball_owner != self.ball_owner):
		return;
	
	if(other is Hitbox):
		if(other.ball_owner == self.ball_owner):
			return;
			
		if !unclashable && !other.unclashable && !is_clash_on_cd():
			weapon.on_weapon_clash(other.ball_owner);
			weapon_clash_cd_elapsed = -0.05;
			return;

	if other is Hurtbox && other.ball_owner != ball_owner && weapon.melee:
		add_to_targets(other.ball_owner);

func _on_area_exited(other: Area2D) -> void:
	if(other is Hurtbox):
		# remove_from_targets(other.ball_owner);
		pass;

func add_to_targets(v:BattleBall):
	if(ignored_targets.has(v)): return;
	target_cd[v] = 0.0;

func remove_from_targets(v:BattleBall):
	target_cd.erase(v);

func add_to_ignored(v:BattleBall):
	ignored_targets[v] = 0;

func remove_from_ignored(v:BattleBall):
	if(!ignored_targets.has(v)): return;
	ignored_targets.erase(v);

func refresh_target_cd(ball:BattleBall):
	target_cd[ball] = (1.0 / weapon.attack_speed) + weapon.hitstop;

func is_clash_on_cd() -> bool:
	return weapon_clash_cd_elapsed < weapon_clash_cd;

func is_overlapping_target(t:BattleBall) -> bool:
	if(!monitoring): return false;
	for area in get_overlapping_areas():
		if(area is Hurtbox && area.ball_owner == t): return true;
	return false;
