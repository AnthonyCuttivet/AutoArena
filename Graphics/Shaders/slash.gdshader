shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

uniform float time_scale : hint_range(0.0, 8.0) = 1.0;
uniform bool use_time = false;

uniform float emission_strength : hint_range(0.0, 5.0) = 1.0;

uniform sampler2D base_noise;
uniform sampler2D width_gradient_mask;
uniform sampler2D length_gradient_mask;
uniform sampler2D highlight;
uniform sampler2D color_lookup;

uniform float zoom : hint_range(0.1, 2.0) = 0.6;
uniform float rotate_all : hint_range(0.0, 360.0) = 0.0;
uniform float anim_rot_amt : hint_range(0.0, 1.0) = 1.0;
uniform float angular_breakup : hint_range(0.0, 1.0) = 0.4;

vec2 rotate_uv(vec2 uv, vec2 pivot, float angle) {
	mat2 rot = mat2(
		vec2(cos(angle), -sin(angle)),
		vec2(sin(angle),  cos(angle))
	);

	uv -= pivot;
	uv = rot * uv;
	uv += pivot;

	return uv;
}

float ease_out_expo(float x) {
	return x >= 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * x);
}

float ease_in_out(float x) {
	if (x < 0.5) {
		return (1.0 - sqrt(1.0 - pow(2.0 * x, 2.0))) * 0.5;
	}

	return (sqrt(1.0 - pow(-2.0 * x + 2.0, 2.0)) + 1.0) * 0.5;
}

vec2 polar_coordinates(
	vec2 uv,
	vec2 center,
	float zoomm,
	float repeat
){
	vec2 dir = uv - center;

	float radius = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x);

	angle /= PI * 2.0;

	return mod(
		vec2(radius * zoomm, angle * repeat),
		1.0
	);
}

void fragment() {

	float p = use_time
		? fract(TIME * time_scale)
		: progress;

	p = ease_out_expo(p);

vec2 uv =
	polar_coordinates(
		rotate_uv(
			UV,
			vec2(0.5),
			radians(rotate_all)
		),
		vec2(0.5),
		zoom,
		1.0
	);
	
float angle_mask =
    texture(
        base_noise,
        vec2(uv.y * 2.0, 0.5)
    ).r;

	uv = (uv - 0.5) / zoom + 0.5;

	vec4 base = texture(base_noise, uv - vec2(0.0, p));

	vec4 width_mask =
		texture(width_gradient_mask, uv);

	vec4 length_mask =
		texture(
			length_gradient_mask,
			rotate_uv(
				uv - vec2(0.0, ease_in_out(p * anim_rot_amt)),
				vec2(0.5),
				radians(180.0)
			)
		);

	vec4 slash =
		(base - width_mask) - length_mask;

	vec3 colorized =
		texture(
			color_lookup,
			vec2(clamp(slash.r * UV.x, 0.0, 1.0), 0.0)
		).rgb;

	vec4 high =
		clamp(
			texture(highlight, uv) - length_mask,
			0.0,
			1.0
		);

	vec3 final_color =
		clamp(
			colorized + high.rgb,
			0.0,
			1.0
		);

	float start = abs(cos(p * PI));
	float end = abs(cos(p * PI));

	float alpha_mask =
		clamp(
			smoothstep(start, end, slash.r)
			+
			smoothstep(
				clamp(start, 0.0, 0.2),
				clamp(end, 0.0, 0.2),
				high.r * 0.2
			),
			0.0,
			1.0
		);

	COLOR.rgb = final_color * (1.0 + emission_strength);
	COLOR.a = alpha_mask;
}