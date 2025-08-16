class_name Elapser extends Resource

@export var duration: float = 0.0;
var elapsed: float = 0.0;
var active: bool = false;

func update(dt: float) -> bool:
    elapsed += dt;

    if (elapsed >= duration):
        return true;
    else:
        return false;

func get_ratio() -> float:
    return elapsed / duration;

func is_over() -> bool:
    return elapsed >= duration;

func reset():
    elapsed = 0.0;
