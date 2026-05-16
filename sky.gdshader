shader_type sky;

uniform sampler2D sky_view_lut : filter_linear, repeat_disable, hint_default_black;

uniform sampler2D transmittance_tex : filter_linear, repeat_disable, hint_default_black; 

uniform float exposure = 15.0;
uniform vec3 sun_direction;
uniform vec3 sun_color = vec3(1.0);

float hash31(vec3 p3) {
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float get_stars(vec3 rd) {
    vec3 grid = floor(rd * 300.0);
    float n = hash31(grid);
    
    float star = 0.0;
    if (n > 0.999) {
        float size = fract(n * 745.3);
        star = smoothstep(0.1, 1.0, size);
        
        star *= sin(TIME * 2.0 + n * 100.0) * 0.5 + 0.5;
    }
    return star;
}

void sky() {
    vec3 rd = EYEDIR;

    // Background color
    float theta = asin(clamp(rd.y, -1.0, 1.0));
    float adj_v = theta < 0.0 ? -sqrt(-theta / (PI / 2.0)) : sqrt(theta / (PI / 2.0));
    float v = adj_v * 0.5 + 0.5; 
    float phi = atan(rd.z, rd.x); 
    if (phi < 0.0) phi += 2.0 * PI;
    float u = phi / (2.0 * PI);

    vec3 L_accum = texture(sky_view_lut, vec2(u, v)).rgb;
    vec3 sky_tonemapped = vec3(1.0) - exp(-L_accum * exposure);

	// sun calculation
    float trans_u = sun_direction.y * 0.5 + 0.5;
    vec3 physical_sun_transmittance = texture(transmittance_tex, vec2(trans_u, 0.0)).rgb;
    
    vec3 final_sun_color = sun_color * physical_sun_transmittance;

    float sun_dot = dot(rd, sun_direction);
    float sun_disc = smoothstep(0.995, 0.9995, sun_dot);
    
    float sun_halo = pow(max(0.0, sun_dot), 400.0); 

    float sun_height_factor = clamp(sun_direction.y * 5.0, 0.0, 1.0);
    float core_mult = mix(5.0, 50.0, sun_height_factor); 

    vec3 sun_total = final_sun_color * (sun_disc * core_mult + sun_halo);
    
    float sun_visibility = smoothstep(-0.02, 0.05, sun_direction.y);
    sun_total *= sun_visibility;
	
	float radial_glow = pow(max(0.0, sun_dot), 1.5); 
    float horizon_mask = smoothstep(0.8, 0.0, abs(rd.y));
    float golden_mask = max(radial_glow, horizon_mask * 0.5);
    
    float sunset_intensity = max(0.0, physical_sun_transmittance.r - physical_sun_transmittance.b);
    
    vec3 golden_tint = vec3(1.5, 1.2, 0.8); 
    sky_tonemapped *= mix(vec3(1.0), golden_tint, golden_mask * sunset_intensity * 0.5);
    sky_tonemapped = clamp(sky_tonemapped, 0.0, 1.0);

	vec3 final_sky_color = sky_tonemapped + sun_total;

    // starsky
    float star_intensity = get_stars(rd);
    
    float night_mask = smoothstep(0.05, -0.1, sun_direction.y);
    
    vec3 star_color = vec3(0.8, 0.9, 1.0) * star_intensity * night_mask;
    
    float horizon_mask_stars = smoothstep(-0.05, 0.05, rd.y);
    star_color *= horizon_mask_stars;

    COLOR = final_sky_color + star_color;
}