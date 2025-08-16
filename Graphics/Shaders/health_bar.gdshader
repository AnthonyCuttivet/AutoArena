shader_type canvas_item;

uniform vec4 fill_color : source_color = vec4(0.2, 1.0, 0.4, 1.0);
uniform float time_speed = 2.0;
uniform float glow_intensity = 0.1;

void fragment() {
    float t = TIME * time_speed;
    float glow = sin(UV.x * 20.0 + t) * glow_intensity;
    COLOR = fill_color + vec4(glow, glow, glow, 0.0);
}
