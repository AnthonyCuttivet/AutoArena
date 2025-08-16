shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0, 0.6, 0.1, 1.0);
uniform float radius = 0.4;      // radius in UV space
uniform float thickness = 0.05;  // ring thickness
uniform float gap_start_deg = 0.0;   // where the gap starts (degrees)
uniform float gap_end_deg = 0.001;    // where the gap ends (degrees)
uniform float aa_width = 0.005;      // anti-alias width

void fragment() {
    // UV centered at (0.5, 0.5)
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);

    // Ring mask
    float ring_edge = abs(dist - radius);
    float ring_mask = smoothstep(thickness * 0.5 + aa_width, thickness * 0.5 - aa_width, ring_edge);

    // Angle in degrees, 0° is up, CCW
    float angle_rad = atan(uv.y, uv.x);
    float angle_deg = degrees(angle_rad);
    angle_deg = mod(angle_deg + 450.0, 360.0);  // Rotate so 0° is up

    // Gap handling — normalize angles
    float start_angle = mod(gap_start_deg, 360.0);
    float end_angle = mod(gap_end_deg, 360.0);

    // Determine if inside gap
    bool in_gap = false;
    if (start_angle < end_angle) {
        in_gap = angle_deg >= start_angle && angle_deg <= end_angle;
    } else {
        in_gap = angle_deg >= start_angle || angle_deg <= end_angle;
    }

    // Final alpha
    float alpha = ring_mask * float(!in_gap);

    COLOR = vec4(color.rgb, color.a * alpha);
}
