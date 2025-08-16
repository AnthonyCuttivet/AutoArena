class_name PodiumSlot extends Control

@onready var weapon_root_1: CollisionShape2D = $Balls/BattleBall/Root
@onready var weapon_slot_1: Node2D = $Balls/BattleBall/Root/WeaponSlot
@onready var weapon_1: Sprite2D = $Balls/BattleBall/Root/WeaponSlot/Sprite2D
@onready var color_1: Sprite2D = $Balls/BattleBall/Root/Circle

@onready var weapon_root_2: CollisionShape2D = $Balls/BattleBall2/Root
@onready var weapon_slot_2: Node2D = $Balls/BattleBall2/Root/WeaponSlot
@onready var weapon_2: Sprite2D = $Balls/BattleBall2/Root/WeaponSlot/Sprite2D
@onready var color_2: Sprite2D = $Balls/BattleBall2/Root/Circle

@onready var crown: TextureRect = $Crown
@onready var time_text: DynamicText = $Texts/TimeText
@onready var damage_done: DynamicText = $Texts/Damage_Done

func fill_data(data:TimeAttackData, time_color:String, time_freq:String):
	time_text.format([time_freq, time_color, Utils.convert_time_to_string(data.time)]);
	damage_done.format(
		[
			data.ball_1_color.to_html(), str(data.ball_1_damage),
			data.ball_2_color.to_html(), str(data.ball_2_damage)
		]
	);
	
	color_1.self_modulate = data.ball_1_color;
	weapon_1.texture = data.ball_1_sprite;
	weapon_1.flip_h = data.ball_1_flip_h;
	weapon_1.position.x = data.ball_1_offset;
	#weapo.rotation += data.ball_1_rot;

	color_2.self_modulate = data.ball_2_color;
	weapon_2.texture = data.ball_2_sprite;
	weapon_2.flip_h = data.ball_2_flip_h;
	weapon_2.position.x = data.ball_2_offset;
	#weapon_slot_2.rotation += data.ball_2_rot;
	
	
