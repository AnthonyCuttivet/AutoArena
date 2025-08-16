class_name PlayerHUD extends VBoxContainer

@onready var health_under_bar: TextureProgressBar = $HealthBar/BarLeft/HealthBar/MarginContainer/UnderBar
@onready var health_main_bar: TextureProgressBar = $HealthBar/BarLeft/HealthBar/MarginContainer/MainBar
@onready var player_name_label: RichTextLabel = $PlayerInfos/Control/Node2D/PlayerNameLabel

@onready var player_color_notch: ColorRect = $PlayerInfos/Control/ColorNotch
@onready var player_combo_value: RichTextLabel = $PlayerGameValues/Node2D/ComboValue
@onready var player_combo: RichTextLabel = $PlayerGameValues/Node2D/ComboText

@onready var fire: FireRoot = $PlayerGameValues/Node2D/FireRoot
@onready var hp_value: RichTextLabel = $HealthBar/BarLeft/HealthBar/MarginContainer/MainBar/Node2D/HBoxContainer/HpValue
@onready var low_health_label: RichTextLabel = $PlayerInfos/Control/Node2D/LowHealthLabel
@onready var hp_label: RichTextLabel = $HealthBar/BarLeft/HealthBar/MarginContainer/MainBar/Node2D/HBoxContainer/HPLabel
