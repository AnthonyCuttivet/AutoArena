shader_type particles;

uniform vec2 target_pos;
uniform float attraction_strength = 5.0; // how strong the pull is
uniform float turn_rate = 2.0;           // how fast particles curve toward target

void process() {
    // Current particle position (xy part of transform)
    vec2 particle_pos = TRANSFORM[2].xy;

    // Direction toward target
    vec2 dir2D = normalize(target_pos - particle_pos);

    // Current velocity as vec2
    vec2 vel2D = VELOCITY.xy;

    // If particle has no speed, give it a default
    if (length(vel2D) < 0.001) {
        vel2D = vec2(0.0, -1.0); // straight up
    }

    // Blend between current velocity and target direction -> steering
    vec2 new_dir = normalize(mix(normalize(vel2D), dir2D, turn_rate * DELTA));

    // Keep original speed but steer toward new_dir
    float speed = length(vel2D);
    vel2D = new_dir * speed;

    // Apply attraction (increasing speed toward target)
    vel2D += dir2D * attraction_strength * DELTA;

    // Reassign to VELOCITY
    VELOCITY = vec3(vel2D, 0.0);
}
