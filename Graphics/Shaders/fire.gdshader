shader_type canvas_item;
render_mode blend_add;

uniform float combo_intensity = 1.0;
uniform float time;

void fragment() {
	vec2 uv = UV;
	uv.y += sin(uv.x * 20.0 + time * 4.0) * 0.05 * combo_intensity;
	uv.y *= combo_intensity;

	float flame = smoothstep(0.8, 0.0, uv.y); // fade top to bottom
	flame *= smoothstep(0.0, 0.5, uv.x) * smoothstep(1.0, 0.5, uv.x); // horizontal taper
	flame *= 1.0 + sin(time * 10.0 + uv.x * 50.0) * 0.2; // flicker

	COLOR = vec4(1.0, 0.3 + flame * 0.7, 0.0, flame);
}
