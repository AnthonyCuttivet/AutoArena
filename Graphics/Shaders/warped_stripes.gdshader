shader_type canvas_item;

uniform float stripes = 4.82;
uniform float stripe_thickness = 1.33;
uniform vec3 stripe_color : source_color = vec3(0.59, .98, .69);
uniform vec3 background_color : source_color = vec3(0, 0, 0);
uniform float uv_offset = 0.5;
uniform float warp_strength = 50.0;
uniform float warp_uv_mult = 2.0;
uniform float wave_strength = 1.0;
uniform float oscillation_mult = 0.2;
uniform float rotation = 0.05;
uniform float rot_time = 10.0;

uniform vec4 flash_color: source_color = vec4(1.0);
uniform float flash_intensity: hint_range(0.0, 1.0);


vec2 rot(vec2 uv, float angle) {
	float s = sin(angle);
	float c = cos(angle);
	mat2 rotation_matrix = mat2(vec2(c, s), vec2(-s, c));
	return uv * rotation_matrix;
}


void fragment() {
	vec2 uv = UV - uv_offset;
	uv = rot(uv, -0.2 + sin(rot_time) * rotation);
	float osc = sin(uv.x * (uv.x + uv_offset) * wave_strength) * oscillation_mult;
	uv.y += osc * sin(warp_strength + uv.x * warp_uv_mult);
	uv.y = fract(uv.y * stripes);
	float mask = smoothstep(0.5, 0.55, uv.y);
	mask -= smoothstep(0.5 + stripe_thickness, 0.55 + stripe_thickness, uv.y);
	vec3 final_color = mix(background_color.rgb, stripe_color.rgb, mask);
	COLOR = vec4(final_color, 1.0);

	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash_intensity);
}