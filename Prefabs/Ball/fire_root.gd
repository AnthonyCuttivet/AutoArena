class_name FireRoot extends Node2D

@export var fire_color_gradient: GradientTexture1D;

func get_shader() -> Material:
	return get_child(0).get_child(0).material;

func set_intensity(v: float):
	v = clamp(v, 0.0, 1.0);
	get_shader().set("shader_parameter/intensity", v);

func set_fire_color(color: Color):
	fire_color_gradient.gradient.colors[0] = color;
	fire_color_gradient.gradient.colors[0].a = 0.0;
	fire_color_gradient.gradient.colors[1] = color;

	get_shader().set("shader_parameter/Texture_COLOR", fire_color_gradient);
