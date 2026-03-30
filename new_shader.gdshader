shader_type canvas_item;

// radius
const float R_GROUND = 6360.0;
const float R_ATMOSPHERE = 6420.0;

// Rayleigh Coefficients
const vec3 RAYLEIGH_BETA = vec3(0.0058, 0.0135, 0.0331);
const float RAYLEIGH_SCALE_HEIGHT = 8.0;

// calculate sphere and ray hitting point
vec2 ray_sphere_intersect(vec3 ray_origin, vec3 ray_dir, float sphere_radius) {
    float a = dot(ray_dir, ray_dir);
    float b = 2.0 * dot(ray_origin, ray_dir);
    float c = dot(ray_origin, ray_origin) - (sphere_radius * sphere_radius);
    float d = (b * b) - 4.0 * a * c;
    if (d < 0.0) return vec2(-1.0);
    return vec2((-b - sqrt(d)) / (2.0 * a), (-b + sqrt(d)) / (2.0 * a));
}

void fragment() {
    // UV.y to r (ground to higher)
    float r = mix(R_GROUND, R_ATMOSPHERE, UV.y);
    
    // UV.x to theta
    float cos_theta = 1.0 - 2.0 * UV.x;
    float sin_theta = sqrt(max(0.0, 1.0 - cos_theta * cos_theta));
    
    // camera position
    vec3 ray_origin = vec3(0.0, r, 0.0);
    vec3 ray_dir = vec3(sin_theta, cos_theta, 0.0);
    
    vec2 intersection = ray_sphere_intersect(ray_origin, ray_dir, R_ATMOSPHERE);
    float ray_length = intersection.y;
    
    // hit the ground
    vec2 ground_intersect = ray_sphere_intersect(ray_origin, ray_dir, R_GROUND);
    if (ground_intersect.y > 0.0 && ground_intersect.x > 0.0) {
        ray_length = ground_intersect.x;
    }

    // Ray Marching
    const int STEPS = 40;
    float step_size = ray_length / float(STEPS);
    float current_t = 0.5 * step_size;
    
    vec3 optical_depth = vec3(0.0);
    
    for (int i = 0; i < STEPS; i++) {
        vec3 sample_pos = ray_origin + ray_dir * current_t;
        float sample_height = length(sample_pos) - R_GROUND;
        
        float density = exp(-sample_height / RAYLEIGH_SCALE_HEIGHT);
        optical_depth += density * step_size * RAYLEIGH_BETA;
        
        current_t += step_size;
    }
    
    vec3 transmittance = exp(-optical_depth);
    
    // hit the ground
    if (ground_intersect.y > 0.0 && ground_intersect.x > 0.0) {
        transmittance = vec3(0.0);
    }
    
    COLOR = vec4(transmittance, 1.0);
}