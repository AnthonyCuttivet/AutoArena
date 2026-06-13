shader_type canvas_item;

uniform vec2 texture_offset = vec2(0.0, 0.0);
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// --- Lifetime ---
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// --- Diffraction / RGB Split ---
uniform float aberration : hint_range(0.0, 1.0) = 0.025;
uniform float aberration_bands : hint_range(1.0, 20.0) = 8.0;
// --- Broken Mirror Facets ---
uniform float facet_count : hint_range(1.0, 32.0) = 12.0;
uniform float facet_power : hint_range(0.0, 0.1) = 0.04;
uniform float facet_angle : hint_range(0.0, 1.0) = 0.0; // 0 = vertical slices, 0.5 = diagonal, 1 = horizontal
// --- Flicker ---
uniform float flicker_speed : hint_range(0.0, 30.0) = 20.0;
uniform float flicker_intensity : hint_range(0.0, 1.0) = 0.4;
// --- Edge Dissolve ---
uniform float dissolve_sharpness : hint_range(1.0, 20.0) = 6.0;

float rand(float seed) {
    return fract(sin(seed * 127.1 + 311.7) * 43758.5453);
}

void fragment() {
    float time_snap = floor(TIME * flicker_speed);

    // --- Rotated facet axis ---
    vec2 centered = UV - vec2(0.5);
    float angle = facet_angle * 3.14159 * 0.5; // 0 to 90 degrees
    vec2 rotated = vec2(
        centered.x * cos(angle) - centered.y * sin(angle),
        centered.x * sin(angle) + centered.y * cos(angle)
    );
    float facet = floor((rotated.x + 0.5) * facet_count);

    // --- Facet displacement (perpendicular to slice axis) ---
    // Displacement direction rotates with the facets
    float perp_angle = angle + 3.14159 * 0.5;
    vec2 perp_dir = vec2(cos(perp_angle), sin(perp_angle));
    vec2 secondary_dir = vec2(cos(angle), sin(angle));

    float primary_offset = (rand(facet + time_snap * 0.3) - 0.5) * facet_power * (1.0 - progress);
    float secondary_offset = (rand(facet + time_snap * 0.5 + 99.0) - 0.5) * facet_power * 2.0 * (1.0 - progress);

    vec2 facet_displacement = perp_dir * primary_offset + secondary_dir * secondary_offset;

    // --- Aberration bands (also rotated) ---
    float band_axis = rotated.y + 0.5;
    float band = floor(band_axis * aberration_bands);
    float band_aberration = aberration * rand(band + time_snap * 0.1) * 2.0 * (1.0 - progress);

    vec2 uv = UV + facet_displacement + texture_offset;

    // --- RGB Split ---
    float flicker_dir = rand(time_snap) * 2.0 - 1.0;
    vec2 aber_dir = vec2(cos(angle), sin(angle)) * band_aberration * flicker_dir;
    vec2 r_uv = clamp(uv + aber_dir, vec2(0.0), vec2(1.0));
    vec2 b_uv = clamp(uv - aber_dir, vec2(0.0), vec2(1.0));
    uv = clamp(uv, vec2(0.0), vec2(1.0));

    float r = texture(TEXTURE, r_uv).r;
    float g = texture(TEXTURE, uv).g;
    float b = texture(TEXTURE, b_uv).b;
    float a = texture(TEXTURE, uv).a;

    // --- Flicker per facet ---
    float flicker = 1.0 - (rand(facet + time_snap * 0.7) * flicker_intensity * (1.0 - progress));

    // --- Edge dissolve ---
    float edge_dist = min(UV.x, 1.0 - UV.x) * 2.0;
    float dissolve_mask = smoothstep(progress - 0.1, progress + 0.1, edge_dist * pow(1.0 - progress, 1.0 / dissolve_sharpness));

    float final_alpha = a * flicker * dissolve_mask;

    COLOR = vec4(r, g, b, final_alpha) * tint;
}