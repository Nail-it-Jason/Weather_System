shader_type sky;

uniform sampler2D sky_view_lut : filter_linear, repeat_disable, hint_default_black;
uniform float exposure = 15.0;

uniform vec3 sun_direction;
uniform vec3 sun_color = vec3(1.0);

void sky() {
    vec3 rd = EYEDIR;

    // decode theta & phi
    float theta = asin(clamp(rd.y, -1.0, 1.0));
    float adj_v;
    if (theta < 0.0) {
        adj_v = -sqrt(-theta / (PI / 2.0));
    } else {
        adj_v = sqrt(theta / (PI / 2.0));
    }
    float v = adj_v * 0.5 + 0.5; 
    
    float phi = atan(rd.z, rd.x); 
    if (phi < 0.0) phi += 2.0 * PI;
    float u = phi / (2.0 * PI);

	vec3 L_accum = texture(sky_view_lut, vec2(u, v)).rgb;

    // tone map the sky
    vec3 sky_tonemapped = vec3(1.0) - exp(-L_accum * exposure);

    // render the sun
    float sun_dot = dot(rd, sun_direction);
    float sun_disc = smoothstep(0.998, 1.0, sun_dot);
    float sun_halo = pow(max(0.0, sun_dot), 800.0) * 1.5;

    float sun_height = clamp(sun_direction.y * 5.0, 0.0, 1.0);
    
    float core_mult = mix(1.5, 50.0, sun_height); 

    vec3 sun_total = sun_color * (sun_disc * core_mult + sun_halo);

    COLOR = sky_tonemapped + sun_total;
}