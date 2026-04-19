shader_type sky;

// 1. 接收你辛苦做好的 LUT (ViewportTexture)
uniform sampler2D sky_view_lut : filter_linear, hint_default_black;
uniform vec3 sun_direction; // 与其他LUT一致

// 曝光控制 (用于点亮黑夜)
uniform float exposure = 15.0; 

// 工具函数：相位函数 (此处省略，请复用之前的 Mie 和 Rayleigh 代码)

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

void sky() {
    // 1. 获取视线方向 rd ( Godot 提供EYEDIR )
    vec3 rd = EYEDIR;

    // 2. 解码仰角 theta ( Latitude )
    float theta = asin(rd.y); // asin 返回 [-PI/2, PI/2]
    
    // 3. 应用非线性解码公式 (还原平方压缩)
    float adj_v;
    if (theta < 0.0) {
        float l = -theta;
        adj_v = -sqrt(l / (PI / 2.0)); // 下半球
    } else {
        float l = theta;
        adj_v = sqrt(l / (PI / 2.0));  // 上半球
    }
    // 将 adj_v [-1, 1] 转回 V 坐标 [0, 1]
    float v = adj_v * 0.5 + 0.5;

    // 💥 关键一击！修正“上地下天”的方向问题
    // 在这里应用 1.0 - v，将图片中的“地”放到脚底，“天”放到头顶
    float corrected_v = 1.0 - v; 

    // 4. 解码方位角 phi ( Longitude )
    float phi = atan(rd.z, rd.x); // atan2 [-PI, PI]
    float u = (phi + PI) / (2.0 * PI); // 转回 U 坐标 [0, 1]

    // 5. 采样 LUT
    vec3 L_accum = texture(sky_view_lut, vec2(u, corrected_v)).rgb;

    // 6. 添加 Tone-mapping (影调映射)
    // 这一步是将物理光量提亮，并防止过曝的魔法
    vec3 final_color = 1.0 - exp(-L_accum * exposure);

    // 7. 输出最终颜色
    COLOR = final_color;
}