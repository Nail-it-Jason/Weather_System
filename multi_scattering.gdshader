shader_type canvas_item;

// Get Transmittance LUT
uniform sampler2D transmittance_tex;

const float R_ground = 6360.0;
const float R_top = 6460.0;

const vec3 rayleigh_scattering = vec3(5.802, 13.558, 33.1) * 0.001; 
const float mie_scattering = 3.996 * 0.001;                            
const float mie_absorption = 4.40 * 0.001;                             
const float mie_extinction = mie_scattering + mie_absorption; 
const vec3 ozone_absorption = vec3(0.650, 1.881, 0.085) * 0.001; 

const float rayleigh_scale_height = 8.0;
const float mie_scale_height = 1.2;

vec2 ray_sphere_intersect(vec3 ro, vec3 rd, float radius) {
    float b = dot(ro, rd);
    float c = dot(ro, ro) - radius * radius;
    float d = b * b - c;
    if (d < 0.0) return vec2(-1.0, -1.0);
    float sq = sqrt(d);
    return vec2(-b - sq, -b + sq); 
}

// Look Up Transmittance Value
vec3 get_transmittance(vec3 pos, vec3 sun_dir) {
    float r = length(pos);
    float mu = dot(pos, sun_dir) / r; // cos(theta)
    
    // mapping to UV coordinate
    float u = mu * 0.5 + 0.5;
    float v = clamp((r - R_ground) / (R_top - R_ground), 0.0, 1.0);
    
    return texture(transmittance_tex, vec2(u, v)).rgb;
}

// Sphere Fibonacci Sampling, generate ith out of uniformed n vectors
vec3 get_spherical_fibonacci(int i, int n) {
    float golden_ratio_conjugate = 0.61803398875;
    float phi = 2.0 * PI * fract(float(i) * golden_ratio_conjugate);
    float cos_theta = 1.0 - (2.0 * float(i) + 1.0) / float(n);
    float sin_theta = sqrt(max(0.0, 1.0 - cos_theta * cos_theta));
    
    return vec3(cos(phi) * sin_theta, sin(phi) * sin_theta, cos_theta);
}

void fragment() {
    // u = 0.5 + 0.5 * cos(theta_s)
    float sun_cos_theta = (UV.x - 0.5) * 2.0;
    float sun_sin_theta = sqrt(max(0.0, 1.0 - sun_cos_theta * sun_cos_theta));
    vec3 sun_dir = normalize(vec3(sun_sin_theta, sun_cos_theta, 0.0));
    
    // v = (h - R_ground) / (R_top - R_ground)
    float h = mix(R_ground, R_top, 1.0 - UV.y);
    vec3 ro = vec3(0.0, h, 0.0);

    vec3 L_2nd_order = vec3(0.0);
    vec3 f_ms = vec3(0.0);
    
    const int SAMPLE_COUNT = 64;
    const int STEPS = 20;
    
    // Send 64 rays to all directions
    for (int i = 0; i < SAMPLE_COUNT; i++) {
        vec3 rd = get_spherical_fibonacci(i, SAMPLE_COUNT);
        
        vec2 d_ground = ray_sphere_intersect(ro, rd, R_ground);
        float ray_length;
        if (d_ground.x > 0.0) {
            ray_length = d_ground.x;
        } else {
            vec2 d_top = ray_sphere_intersect(ro, rd, R_top);
            ray_length = d_top.y;
        }
        
        float dt = ray_length / float(STEPS);
        float t = 0.0;
        // single scattering light to be added
        vec3 L_prime = vec3(0.0);
		// energy coefficient to be added
        vec3 L_f = vec3(0.0);
        
        float optical_depth_R = 0.0;
        float optical_depth_M = 0.0;
        float optical_depth_O = 0.0;
        
        // Ray Marching
        for (int j = 0; j < STEPS; j++) {
            vec3 pos = ro + rd * (t + dt * 0.5);
            float pos_height = max(0.0, length(pos) - R_ground);
            
            float dRayleigh = exp(-pos_height / rayleigh_scale_height);
            float dMie = exp(-pos_height / mie_scale_height);
            float dOzone = max(0.0, 1.0 - abs(pos_height - 25.0) / 15.0);
            
            optical_depth_R += dRayleigh * dt;
            optical_depth_M += dMie * dt;
            optical_depth_O += dOzone * dt;
            
            vec3 extinction = rayleigh_scattering * optical_depth_R + 
                              mie_extinction * optical_depth_M + 
                              ozone_absorption * optical_depth_O;
            vec3 transmittance_to_ro = exp(-extinction);
            
            vec3 scattering = rayleigh_scattering * dRayleigh + mie_scattering * dMie;
            
            // look up table
            vec3 transmittance_to_sun = get_transmittance(pos, sun_dir);
            
            // update
            L_prime += scattering * transmittance_to_sun * transmittance_to_ro * dt;
            L_f += scattering * transmittance_to_ro * dt;
            
            t += dt;
        }
        
        // Average
        L_2nd_order += L_prime / float(SAMPLE_COUNT);
        f_ms += L_f / float(SAMPLE_COUNT);
    }
    
    // Sum of a geometric series for infinite scattering
    vec3 F_ms = 1.0 / (1.0 - f_ms);
    vec3 Psi_ms = L_2nd_order * F_ms;
    
    COLOR = vec4(Psi_ms, 1.0);
}