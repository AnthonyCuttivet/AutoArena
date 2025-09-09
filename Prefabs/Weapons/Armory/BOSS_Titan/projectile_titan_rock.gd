class_name ProjectileTitanRock extends Projectile

@export var sfx_hit:SFX;
@export var wall: StaticBody2D;

@onready var healthbar: Node2D = $Sprite2D/Health

var max_hp:int = 3;
var hp:int = 0;
var inactive_for:float = 0.0;

func init(o:BattleBall, s:float, p:int = -1, b:int = -1):
	super.init(o,s,p,b);
	hp = max_hp;
	set_state(false);

func _process(delta: float) -> void:
	if(is_inactive()):
		inactive_for -= delta;
		if(!is_inactive()):
			set_state(true);
			inactive_for = 0.0;

func _on_weapon_hitbox_area_entered(other: Area2D) -> void:
	if(!other is Hurtbox && !other is Hitbox): return;

	if(other is Hitbox):
		other.weapon.on_weapon_clash(self, self.global_position, false);

	on_rock_hit();


func on_rock_hit():
	# sprite_2d.material.set_shader_parameter("sensitivity", (max_hp - hp + 1) * 0.02);

	if(hit_health()):
		weapon_owner.on_rock_destroyed(self);

func is_inactive() -> bool:
	return inactive_for > 0.0;

func set_state(s:bool):
	wall.collision_layer = 1 if s else 16;
	hitbox.monitoring = s;
	hitbox.monitorable = s;

func hit_health() -> bool:
	hp -= 1;
	healthbar.get_child(hp).self_modulate = Color(0.3,0.3,0.3,1);

	return hp == 0;
