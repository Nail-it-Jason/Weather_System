shader_type canvas_item;

uniform sampler2D transmittance_tex;
uniform sampler2D multi_scattering_tex;
uniform vec3 sun_direction;
uniform float view_height = 6360.5; // 500m above

const float R_ground = 6360.0;
const float R_top = 6460.0;

const vec3 rayleigh_scattering = vec3(5.802, 13.558, 33.1) * 0.001; 
const float mie_scattering = 3.996 * 0.001;                            
const float mie_extinction = (3.996 + 4.40) * 0.001; 
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

vec3 get_transmittance(vec3 pos, vec3 sun_dir) {
    float r = length(pos);
    float mu = dot(pos, sun_dir) / r;
    float u = mu * 0.5 + 0.5;
    float v = clamp((r - R_ground) / (R_top - R_ground), 0.0, 1.0);
    return texture(transmittance_tex, vec2(u, v)).rgb;
}

// phase function
float phase_rayleigh(float cos_theta) {
    return 3.0 * (1.0 + cos_theta * cos_theta) / (16.0 * PI);
}

float phase_mie(float cos_theta) {
    float g = 0.8;
    float g2 = g * g;
    return 3.0 * (1.0 - g2) * (1.0 + cos_theta * cos_theta) / 
           (8.0 * PI * (2.0 + g2) * pow(1.0 + g2 - 2.0 * g * cos_theta, 1.5));
}

void fragment() {
    // longtitude phi (0 to 2PI)
    float phi = (UV.x) * 2.0 * PI;
    
    // latitude theta (Non-linear)
    float v = UV.y;
    float theta;
    if (v < 0.5) {
        float coord = 1.0 - 2.0 * v;
        theta = -coord * coord * (PI / 2.0);
    } else {
        float coord = 2.0 * v - 1.0;
        theta = coord * coord * (PI / 2.0);
    }

    vec3 view_dir = vec3(cos(theta) * cos(phi), sin(theta), cos(theta) * sin(phi));

    vec3 ro = vec3(0.0, view_height, 0.0);
    vec2 d_top = ray_sphere_intersect(ro, view_dir, R_top);
    vec2 d_ground = ray_sphere_intersect(ro, view_dir, R_ground);
    
    float ray_length = d_top.y;
    if (d_ground.x > 0.0) ray_length = d_ground.x;

    const int STEPS = 30;
    float dt = ray_length / float(STEPS);
    
    vec3 L_accum = vec3(0.0);
    vec3 T_accum = vec3(1.0);
    float t = 0.0;

    for (int i = 0; i < STEPS; i++) {
        vec3 pos = ro + view_dir * (t + dt * 0.5);
        float h = max(0.0, length(pos) - R_ground);
        
        float dR = exp(-h / rayleigh_scale_height);
        float dM = exp(-h / mie_scale_height);
        
        vec3 sig_s = rayleigh_scattering * dR + mie_scattering * dM;
        vec3 sig_e = sig_s + (4.40 * 0.001 * dM) + (ozone_absorption * max(0.0, 1.0 - abs(h - 25.0) / 15.0));

        // single + multi scattering
        vec3 T_sun = get_transmittance(pos, sun_direction);
        
        // multi scattering LUT
        float ms_u = dot(normalize(pos), sun_direction) * 0.5 + 0.5;
        float ms_v = clamp((length(pos) - R_ground) / (R_top - R_ground), 0.0, 1.0);

        vec3 L_ms = texture(multi_scattering_tex, vec2(ms_u, ms_v)).rgb;

        float cos_theta_sun = dot(view_dir, sun_direction);
        vec3 phase_sum = rayleigh_scattering * dR * phase_rayleigh(cos_theta_sun) + 
                         mie_scattering * dM * phase_mie(cos_theta_sun);
        
        // add scattered light
        vec3 S = (T_sun * phase_sum + L_ms * sig_s);
        L_accum += T_accum * S * dt;
        
        T_accum *= exp(-sig_e * dt);
        t += dt;
    }

    COLOR = vec4(L_accum, 1.0);
}