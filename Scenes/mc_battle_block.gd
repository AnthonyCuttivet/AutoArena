class_name MCBattleBlock extends RigidBody2D

@export var main:Main;
@export var block_value:int = 1;
@export var block_death_shake:float = 1.0;
@export var sfx_hit:SFX;
@export var sfx_break:SFX;
@export var value:DynamicText;
@export var collider:CollisionShape2D;
@export var sprite:Sprite2D;
@export var stx:CompressedTexture2D;
@export var depth:int = 0;
@export var parent:BlockModeMCDig = null;

@onready var hurtbox: BattleBlockHurtbox = $Hurtbox
@onready var value_ui: DynamicText = $Value

var current_value:int = 0;
var block_index:int = 0;
var team:int = 0;


func _ready() -> void:
	hurtbox.ball_owner = BattleBall.new();
	hurtbox.ball_owner.health = 99;
	hurtbox.ball_owner.team = -99;
	hurtbox.ball_owner.hp_text = value;
	hurtbox.ball_owner.unkillable = true;
	hurtbox.ball_owner.silent_on_hit = true;
	hurtbox.ball_owner.weapon = Weapon.new();

	current_value = block_value;
	update_value_text();
	if(!EventBus.ball_damaged.is_connected(on_damaged_received)):
		EventBus.ball_damaged.connect(on_damaged_received);

	sprite.texture = stx;

func on_impact(ball:BattleBall, amount:int):

	current_value -= amount;
	EventBus.ball_duel_scale.emit(ball.get_instance_id());

	ball.weapon.on_weapon_clash(self, self.global_position, false, true);

	if(current_value <= 0):
		block_death(ball);
		return;

	update_value_text();
	AudioManager.play_sfx(sfx_hit, "SFX");
	EventBus.block_hit.emit(ball.get_instance_id(), self);

func block_death(ball:BattleBall):
	if(parent != null):
		parent.on_block_destroyed(ball, self);

	# get_tree().get_current_scene().global_hitstop(0.01, 0.1);
	EventBus.camera_trigger_shake.emit(block_death_shake * block_index);
	AudioManager.play_sfx(sfx_break, "SFX");
	EventBus.block_destroyed.emit(ball.get_instance_id(), self);
	queue_free();

func update_value_text():
	value.format([Utils.format_number_with_dots(current_value)]);
	sprite.self_modulate.a = lerp(0.5, 1.0, clamp(current_value / float(block_value), 0.0, 1.0));

# func update_block_color(ball:BattleBall):
# 	polygon_color.color = ball.color;
# 	if(current_value < ball.scaling_damage):
# 		polygon_color.color.a = 0.9;
# 	else:
# 		polygon_color.color.a = 1.0 - (current_value/float(block_value));

func on_damaged_received(id:int, _amount:int, _from:int):
	if(id != hurtbox.ball_owner.get_instance_id()): return;

	on_impact(main.get_ball_by_id(_from), _amount);
