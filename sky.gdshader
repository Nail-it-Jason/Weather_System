shader_type sky;

uniform sampler2D sky_view_lut : filter_linear, hint_default_black;
uniform float exposure = 15.0; 

void sky() {
    // 1. 获取视线
    vec3 rd = EYEDIR;

    // 2. 解码仰角 theta
    float theta = asin(clamp(rd.y, -1.0, 1.0));
    
    float adj_v;
    if (theta < 0.0) {
        float l = -theta;
        adj_v = -sqrt(l / (PI / 2.0));
    } else {
        float l = theta;
        adj_v = sqrt(l / (PI / 2.0));
    }
    float v = adj_v * 0.5 + 0.5;
    
    v = 1.0 - v; // 翻转对齐
    
    // 3. 解码方位角 phi
    float phi = atan(rd.z, rd.x); 
	if (phi < 0.0) phi += 2.0 * PI;
    float u = (phi + PI) / (2.0 * PI);

    // 4. 采样 LUT
    vec3 L_accum = texture(sky_view_lut, vec2(u, v)).rgb;

    // 5. Tone-mapping (注意这里加了 vec3 确保类型安全)
    vec3 final_color = vec3(1.0) - exp(-L_accum * exposure);

    COLOR = final_color;
}