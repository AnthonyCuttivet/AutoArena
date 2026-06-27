class_name AnimFuncs extends AnimationPlayer
@onready var bg_top: ColorRect = $"../BG/BGTop"
@onready var bg_bot: ColorRect = $"../BG/BGBot"
@onready var sprite_2d: Sprite2D = $"../BattleBall/Root/WeaponSlot/Sprite2D"
@onready var circle: Sprite2D = $"../BattleBall/Root/Circle"
@onready var text: RichTextLabel = $"../Text"

func shake(v:float):
	EventBus.camera_trigger_shake.emit(v);

func setup_new_challenger(b:BattleBall):
	var c:Color = b.color;
	
	bg_top.color = c;
	bg_bot.color = c;
	circle.self_modulate = c;
	text.modulate = c;
	
	sprite_2d.texture = b.weapons[0].sprite_2d.texture;
	text.text = "[wave amp=100.0 freq=3 connected=1] 『 " + b.weapon_settings.name + " 』[/wave]"
