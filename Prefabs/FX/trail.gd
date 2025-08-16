class_name Trail extends Line2D

const MAX_POINTS:int = 2000;

@export var ball:BattleBall;
@onready var curve: Curve2D = Curve2D.new();

func _process(delta: float) -> void:
	curve.add_point(ball.global_position);
	if(curve.get_baked_points().size() > MAX_POINTS):
		curve.remove_point(0);
	
	points = curve.get_baked_points();
