shader_type canvas_item;

// --- Control ---
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.0; // Drive this from GDScript

// --- Tear ---
uniform float tear_block_size : hint_range(1.0, 64.0) = 20.0; // Height of each slice in pixels
uniform float tear_power : hint_range(0.0, 1.0) = 0.05;       // Max UV offset per slice
uniform float tear_speed : hint_range(0.0, 20.0) = 8.0;       // How fast slices shift

// --- RGB Split ---
uniform float rgb_split : hint_range(0.0, 0.05) = 0.015;      // Chromatic aberration spread

// --- Flicker ---
uniform float flicker_speed : hint_range(0.0, 30.0) = 15.0;

float rand(float seed) {
    return fract(sin(seed * 127.1 + 311.7) * 43758.5453);
}

void fragment() {
    if (glitch_intensity <= 0.0) {
        COLOR = texture(TEXTURE, UV);
    } else {
        // --- UV Tearing ---
        float slice = floor(UV.y * (1.0 / TEXTURE_PIXEL_SIZE.y) / tear_block_size);
        float time_seed = floor(TIME * tear_speed);

        float slice_rand = rand(slice + time_seed * 0.1);
        float should_tear = step(1.0 - glitch_intensity, slice_rand);

        float offset = (rand(slice + time_seed) - 0.5) * tear_power * should_tear * glitch_intensity;
        vec2 torn_uv = clamp(UV + vec2(offset, 0.0), vec2(0.0), vec2(1.0));

        // --- RGB Split ---
        float split = rgb_split * glitch_intensity;
        float flicker = rand(floor(TIME * flicker_speed)) * 2.0 - 1.0;
        vec2 r_offset = vec2(split * flicker, 0.0);
        vec2 b_offset = vec2(-split * flicker, 0.0);

        float r = texture(TEXTURE, clamp(torn_uv + r_offset, vec2(0.0), vec2(1.0))).r;
        float g = texture(TEXTURE, torn_uv).g;
        float b = texture(TEXTURE, clamp(torn_uv + b_offset, vec2(0.0), vec2(1.0))).b;
        float a = texture(TEXTURE, torn_uv).a;

        COLOR = vec4(r, g, b, a);
    }
}