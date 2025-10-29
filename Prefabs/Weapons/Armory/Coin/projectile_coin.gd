class_name ProjectileCoin extends Projectile

@export var catch_delay:float = 0.1;

var coin_parent:WeaponCoin = null;
var can_be_caught:bool = false;
var no_destroy_callback:bool = false;
var has_bounced:bool = false;

func init(o:BattleBall, w:Weapon, s:float, p:int = -1, b:int = -1):
	super.init(o,w,s);
	o.get_tree().create_timer(catch_delay).timeout.connect(
		func():
			can_be_caught = true;
			always_clash = true;
	);

func _on_projectile_hitbox_area_entered(other: Area2D) -> void:
	super._on_projectile_hitbox_area_entered(other);

	if(can_be_caught && other is Hurtbox && other.ball_owner == ball_owner && ball_owner.hitstop_remaining <= 0.0):
		coin_parent.on_coin_caught();
		global_position = ball_owner.global_position + (weapon_owner.weapon_slot.global_transform.x * ball_owner.weapon_settings.offset);
		absolute = true;
		accumulated_gravity = 0.0;
		gravity_force = 0.0;
		custom_hitstop = 0.5;
		sprite_2d.texture = coin_parent.coins_sprites[1];
		no_destroy_callback = true;
		velocity = weapon_owner.weapon_slot.global_transform.x * 6666.0;
		scale *= 0.5;

func _on_projectile_hitbox_body_entered(other: Node2D) -> void:
	if(other.name == "WallBot"):
		if(!has_bounced):
			bounce_count = 1;
			has_bounced = true;
			AudioManager.play_sfx(coin_parent.sfx_coin_bounce, "SFX");
		else:
			coin_parent.set_can_shoot(true);

	super._on_projectile_hitbox_body_entered(other);

func destroy(source:int = 0):
	super.destroy(source);

	if(!no_destroy_callback && source >= 2):
		coin_parent.set_can_shoot(true);
