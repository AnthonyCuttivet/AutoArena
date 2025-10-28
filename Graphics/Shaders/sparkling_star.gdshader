shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 color : source_color = vec4(1.,1.,1.,1.);
uniform float scale : hint_range(0.1, 10000.0, 0.1) = 7500;
uniform float circle_ratio: hint_range(0.0, 100.0, 0.1) = 0.;
uniform float decay_magnitude: hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float cut_magnitude: hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float rotate_speed: hint_range(-1000, 1000, 0.01) = 1;
uniform float time_speed: hint_range(-1000, 1000, 0.01) = 1;

uniform float frequency_base: hint_range(0.0, 10.0, 0.01) = 1.;
uniform float frequency_disturbance_scale: hint_range(0.0, 10.0, 0.01) = 0.;
uniform bool stop_shine = false;

float onedx(float x) { return x == 0.0 ? 1.0 : 1.0 / x; }
float onedx2(float x) { return onedx(x) * onedx(x); }

float getBetaW(float x, float f, float size) { return size * x * 3.1415926 / f; }
float getBetaH(float y, float f, float size) { return size * y * 3.1415926 / f; }

float getI(vec2 uv, float f, vec2 SIZE) {
	return onedx2(getBetaW(uv.x, f, SIZE.x)) * onedx2(getBetaH(uv.y, f, SIZE.y));
}

vec2 rotate(vec2 uv, float addtheta) {
    float theta = atan(uv.y, uv.x) + addtheta;
    float r = length(uv);
    return r * vec2(cos(theta), sin(theta));
}

void fragment() {
    vec2 st = rotate((UV - 0.5) * scale, TIME * rotate_speed);
	float r = length(st);
    st *= pow(r, circle_ratio);
    float time = TIME * time_speed;

    float f = frequency_base + frequency_disturbance_scale *
        (3.*sin(time) + 2.*cos(time*4.) + 6.*sin(time*2.) + sin(time*3.));
    f = stop_shine ? frequency_base : f;

	float L = distance(UV, st);
	float M = exp(-L*L * decay_magnitude * decay_magnitude / scale);
	M = M < 0.05 ? 0. : M;

    // compute color & transparency
	float intensity = M * color.a;
	vec3 col = min(vec3(getI(st, f, SCREEN_PIXEL_SIZE)) * M, 1.) * color.rgb;

	COLOR = vec4(col, intensity);
}
