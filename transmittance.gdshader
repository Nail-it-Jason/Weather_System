shader_type canvas_item;

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

void fragment() {
    float r = mix(R_ground, R_top, UV.y);
    float mu = mix(-1.0, 1.0, UV.x);
    
    vec3 ro = vec3(0.0, r, 0.0); 
    vec3 rd = vec3(sqrt(max(0.0, 1.0 - mu * mu)), mu, 0.0); 

    vec2 d_ground = ray_sphere_intersect(ro, rd, R_ground);
    
    if (d_ground.x > 0.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        vec2 d_top = ray_sphere_intersect(ro, rd, R_top);
        float ray_length = d_top.y; 

        const int STEPS = 40;
        float dt = ray_length / float(STEPS);
        
        vec3 optical_depth_R = vec3(0.0); 
        float optical_depth_M = 0.0;      
        vec3 optical_depth_O = vec3(0.0); 

        float t = 0.0;
        for (int i = 0; i < STEPS; i++) {
            vec3 pos = ro + rd * (t + dt * 0.5);
            float h = length(pos) - R_ground; 
            h = max(0.0, h);

            float dRayleigh = exp(-h / rayleigh_scale_height);
            float dMie = exp(-h / mie_scale_height);
            float dOzone = max(0.0, 1.0 - abs(h - 25.0) / 15.0);

            optical_depth_R += dRayleigh * dt * vec3(1.0); 
            optical_depth_M += dMie * dt;
            optical_depth_O += dOzone * dt * vec3(1.0); 

            t += dt;
        }

        vec3 extinction = rayleigh_scattering * optical_depth_R + 
                          mie_extinction * optical_depth_M + 
                          ozone_absorption * optical_depth_O;
                          
        vec3 transmittance = exp(-extinction);
        COLOR = vec4(transmittance, 1.0);
    }
}