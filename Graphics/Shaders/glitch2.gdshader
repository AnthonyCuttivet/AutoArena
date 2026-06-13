shader_type canvas_item;

uniform float intensity : hint_range(0.0, 0.1) = 0.005;
uniform float glitch_strength : hint_range(0.0, 2.0) = 0.3;
uniform float time_scale : hint_range(0.0, 10.0) = 3.0;
uniform float glitch_rotation_degrees : hint_range(0.0, 360.0) = 0.0;
uniform float band_count : hint_range(1.0, 100.0) = 20.0;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;

    float angle = radians(glitch_rotation_degrees);

    // Direction of movement
    vec2 dir = vec2(cos(angle), sin(angle));

    // Direction used to generate bands
    vec2 band_dir = vec2(-dir.y, dir.x);

    float t = TIME * time_scale;

    // Compute which band we're in
    float band_coord = dot(uv, band_dir);
    float band_id = floor(band_coord * band_count) / band_count;

    float slice_rand = rand(vec2(band_id, floor(t * 8.0)));
    float glitch_offset = (slice_rand - 0.5) * glitch_strength * 0.05;
    float glitch_on = step(0.85, rand(vec2(band_id, floor(t * 5.0))));

    uv += dir * glitch_offset * glitch_on;

    float r = texture(screen_texture, uv + dir * intensity).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv - dir * intensity).b;

    vec4 self = texture(TEXTURE, UV);
    COLOR = vec4(r, g, b, self.a);
}