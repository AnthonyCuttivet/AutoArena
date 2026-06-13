shader_type canvas_item;

uniform float strength : hint_range(-1.0, 1.0) = 0.1; // negative = barrel, positive = pincushion
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

void fragment() {
    vec2 uv = SCREEN_UV - 0.5; // centre origin
    float dist = length(uv);
    
    // Fisheye distortion — stronger at edges, zero at centre
    vec2 distorted = uv * (1.0 + strength * dist * dist);
    distorted += 0.5; // restore origin
    
    COLOR = texture(screen_texture, distorted);
}