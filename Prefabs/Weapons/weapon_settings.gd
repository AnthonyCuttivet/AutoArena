class_name WeaponSettings extends Resource

@export var name = "UNKNOWN";
@export var spr:Texture;

@export var melee:bool = true;
@export var ranged:bool = false;
@export var flip:bool = false;
@export var offset:float = 0.0;
@export var y_offset:bool = false;

@export var base_rotation_direction:int = 1;
@export var base_rotation_speed:float = 1.0;
@export var base_damage:int = 1;
@export var base_knockback:float = 3000.0;
@export var base_attack_speed:float = 1.0;
@export var base_shoot_speed:float = 1.0;
@export var base_size:float = 1.0;
@export var base_hitstop:float = 0.2;
@export var base_projectiles: int = 0;
@export var base_projectile_speed:float = 1000.0;
@export var base_projectile_scale:float = 0.75;
@export var base_shoot_duration:float = 0.35;
@export var base_rot_speed_bounce_boost:bool = false;
@export var projectile_self_hitstop:bool = false;
@export var lifesteal:bool = false;
@export var lifesteal_tick:int = 1;

@export var stat_scale_value:float = 1.0;
@export var stat_scale_name:String = "NULL";
@export var scaling_stat_float:bool = false;

@export var no_rotation_change:bool = false;
@export var no_projectile_scale_change:bool = false;

@export var weapon_prefab:PackedScene;
@export var projectile_prefab:PackedScene;
@export var bg_projectile:bool = false;
@export var details:String;
@export var white_details:bool = false;

@export var sfx_clash:SFX;
@export var sfx_hit:SFX;
@export var sfx_shoot:SFX;

@export var leaderboard_offset:float = 1.0;
@export var leaderboard_rotation:float = 0.0;

@export var scale_stat_multiplier:int = 1;
@export var base_damage_multiplier:int = 1;
@export var no_clash_on_block:bool = false;
