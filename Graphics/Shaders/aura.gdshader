shader_type canvas_item;

uniform float outline_width : hint_range(0.5, 5.0) = 1.0;
uniform vec4 color_a : source_color = vec4(1.0, 0.3, 0.0, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 0.9, 0.2, 1.0);
uniform float scroll_speed : hint_range(0.0, 5.0) = 1.5;
uniform float gradient_scale : hint_range(0.5, 10.0) = 3.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec2 px = TEXTURE_PIXEL_SIZE * outline_width;
    float center_alpha = texture(TEXTURE, UV).a;

    // Sample 4 neighbors to detect edge (outline only where sprite has alpha nearby but not here)
    float a_up    = texture(TEXTURE, UV + vec2(0.0, -px.y)).a;
    float a_down  = texture(TEXTURE, UV + vec2(0.0,  px.y)).a;
    float a_left  = texture(TEXTURE, UV + vec2(-px.x, 0.0)).a;
    float a_right = texture(TEXTURE, UV + vec2( px.x, 0.0)).a;

    float neighbor_max = max(max(a_up, a_down), max(a_left, a_right));

    // Outline = pixel is transparent but has an opaque neighbor
    float outline = clamp(neighbor_max - center_alpha, 0.0, 1.0);

    // Moving gradient along screen space for the "energy flow" look
    float grad_t = (UV.y * gradient_scale) - (TIME * scroll_speed);
    float gradient = fract(grad_t);

    vec3 flame_color = mix(color_a.rgb, color_b.rgb, gradient);

    // Subtle pulse to make it feel alive
    float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_strength;

    COLOR = vec4(flame_color * pulse, outline);
}