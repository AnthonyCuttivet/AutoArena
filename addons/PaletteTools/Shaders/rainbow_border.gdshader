shader_type canvas_item;

uniform float alpha : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float strength : hint_range(0.0, 1.0) = 0.5;
uniform float speed : hint_range(0.0, 10.0) = 0.5;
uniform float angle : hint_range(0.0, 360.0) = 0.0;
uniform float border_thickness : hint_range(0.0, 0.0) = 2.0; // in pixels

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Sample neighbours to detect edge
    vec2 px = TEXTURE_PIXEL_SIZE * border_thickness;
    float a_up    = texture(TEXTURE, UV + vec2(0.0,  px.y)).a;
    float a_down  = texture(TEXTURE, UV + vec2(0.0, -px.y)).a;
    float a_left  = texture(TEXTURE, UV + vec2(-px.x, 0.0)).a;
    float a_right = texture(TEXTURE, UV + vec2( px.x, 0.0)).a;

    // A pixel is on the border if it's opaque but has transparent neighbours
    float min_neighbour = min(min(a_up, a_down), min(a_left, a_right));
    float border_mask = color.a * (1.0 - min_neighbour);

    // Rainbow calculation
    float hue = UV.x * cos(radians(angle)) - UV.y * sin(radians(angle));
    hue = fract(hue + fract(TIME * speed));
    float x = 1.0 - abs(mod(hue / (1.0 / 6.0), 2.0) - 1.0);
    vec3 rainbow;
    if (hue < 1.0/6.0) {
        rainbow = vec3(1.0, x, 0.0);
    } else if (hue < 1.0/3.0) {
        rainbow = vec3(x, 1.0, 0.0);
    } else if (hue < 0.5) {
        rainbow = vec3(0.0, 1.0, x);
    } else if (hue < 2.0/3.0) {
        rainbow = vec3(0.0, x, 1.0);
    } else if (hue < 5.0/6.0) {
        rainbow = vec3(x, 0.0, 1.0);
    } else {
        rainbow = vec3(1.0, 0.0, x);
    }

    vec3 final_color = mix(color.rgb, rainbow, border_mask * strength);
    COLOR = vec4(final_color, color.a * alpha);
}