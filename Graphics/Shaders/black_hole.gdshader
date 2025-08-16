shader_type canvas_item;

uniform vec4 hole_color : source_color = vec4(0.1, 0.0, 0.2, 1.0);
uniform float hole_radius = 0.2;
uniform float glow_radius = 0.4;
uniform float glow_intensity = 1.5;
uniform float swirl_strength = 2.0;
uniform float time_speed = 1.0;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // Swirl effect
    float swirl = swirl_strength * (1.0 - smoothstep(hole_radius, glow_radius, dist));
    angle += swirl * sin(TIME * time_speed);

    // Convert back to Cartesian coordinates
    uv = vec2(cos(angle), sin(angle)) * dist;

    // Distance-based alpha
    float alpha = 1.0 - smoothstep(hole_radius, glow_radius, dist);

    // Glow
    vec3 color = hole_color.rgb * pow(1.0 - dist / glow_radius, glow_intensity);
    COLOR = vec4(color, alpha * hole_color.a);
}
