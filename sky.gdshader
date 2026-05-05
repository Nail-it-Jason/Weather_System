shader_type sky;

uniform sampler2D sky_view_lut : filter_linear, repeat_disable, hint_default_black;

uniform sampler2D transmittance_tex : filter_linear, repeat_disable, hint_default_black; 

uniform float exposure = 15.0;
uniform vec3 sun_direction;
uniform vec3 sun_color = vec3(1.0);


uniform float cloud_coverage = 0.5;
uniform float cloud_size = 5.0;
uniform float cloud_speed = 1.0;

// 2d random noise
float hash(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0,0.0)), hash(i + vec2(1.0,0.0)), u.x),
               mix(hash(i + vec2(0.0,1.0)), hash(i + vec2(1.0,1.0)), u.x), u.y);
}

// FBM
float fbm(vec2 p) {
    float f = 0.0;
    float amp = 0.5;
    for(int i = 0; i < 4; i++) {
        f += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return f;
}


void sky() {
    vec3 rd = EYEDIR;

    // 1. 获取天空底色 (来自 SkyView LUT)
    float theta = asin(clamp(rd.y, -1.0, 1.0));
    float adj_v = theta < 0.0 ? -sqrt(-theta / (PI / 2.0)) : sqrt(theta / (PI / 2.0));
    float v = adj_v * 0.5 + 0.5; 
    float phi = atan(rd.z, rd.x); 
    if (phi < 0.0) phi += 2.0 * PI;
    float u = phi / (2.0 * PI);

    vec3 L_accum = texture(sky_view_lut, vec2(u, v)).rgb;
    vec3 sky_tonemapped = vec3(1.0) - exp(-L_accum * exposure);

    // ==========================================
    // ✨ 2. 极其优雅的物理太阳计算
    // ==========================================
    // 从透射率 LUT 中读取太阳方向的衰减值
    // LUT 的 U 轴是 sun_direction.y 的映射，V 轴是高度 (地面 v=0)
    float trans_u = sun_direction.y * 0.5 + 0.5;
    vec3 physical_sun_transmittance = texture(transmittance_tex, vec2(trans_u, 0.0)).rgb;
    
    // 太阳最终的颜色 = 宇宙中的本色 * 大气透射率
    vec3 final_sun_color = sun_color * physical_sun_transmittance;

    // 绘制太阳形状
    float sun_dot = dot(rd, sun_direction);
    float sun_disc = smoothstep(0.995, 0.9995, sun_dot);
    
    // 因为 SkyViewLUT 已经包含了米氏散射的巨大光晕，所以这里只画极其靠近核心的高光
    float sun_halo = pow(max(0.0, sun_dot), 400.0); 

    // 根据高度调整绝对亮度 (防止透射率极低时太阳彻底黑掉)
    float sun_height_factor = clamp(sun_direction.y * 5.0, 0.0, 1.0);
    float core_mult = mix(5.0, 50.0, sun_height_factor); 

    // 直接用物理计算出的颜色进行渲染
    vec3 sun_total = final_sun_color * (sun_disc * core_mult + sun_halo);
    
    // 剔除地平线以下的无效太阳
    float sun_visibility = smoothstep(-0.02, 0.05, sun_direction.y);
    sun_total *= sun_visibility;
	
	float radial_glow = pow(max(0.0, sun_dot), 1.5); 
    float horizon_mask = smoothstep(0.8, 0.0, abs(rd.y));
    float golden_mask = max(radial_glow, horizon_mask * 0.5);
    
    // 利用透射率的 R 通道动态判断是否处于日落 (日落时透射率红光占比极高)
    float sunset_intensity = max(0.0, physical_sun_transmittance.r - physical_sun_transmittance.b);
    
    vec3 golden_tint = vec3(1.5, 1.2, 0.8); 
    sky_tonemapped *= mix(vec3(1.0), golden_tint, golden_mask * sunset_intensity * 0.5);
    sky_tonemapped = clamp(sky_tonemapped, 0.0, 1.0);

    // 4. 最终输出
    COLOR = sky_tonemapped + sun_total;
	//// ==========================================
    //// ☁️ 云层与火烧云生成逻辑
    //// ==========================================
    //// 1. 生成移动的 UV 坐标 (头顶的云移动快，地平线移动慢，产生 3D 透视感)
    //vec2 cloud_uv = vec2(u * 4.0, adj_v * 2.0); 
    //cloud_uv += TIME * cloud_speed * 0.005; 
    //cloud_uv *= cloud_size;
//
    //// 2. 生成基础云层形态
    //float n = fbm(cloud_uv);
    //
    //// 3. 覆盖率控制 (将连续的噪声变成一朵朵独立的云)
    //// 根据 cloud_coverage 截断噪声，加一点 smoothstep 让边缘羽化
    //float cloud_density = smoothstep(1.0 - cloud_coverage, 1.0 - cloud_coverage + 0.2, n);
    //
    //// 让靠近地平线的云淡出，防止极其边缘的地方拉伸变形
    //cloud_density *= smoothstep(0.0, 0.2, rd.y); 
//
    //// 4. ✨ 火烧云染色魔法！
    //// 正午时，云是白色的。太阳越低，云越会被染成明亮的橘红色/粉紫色！
    //vec3 sunset_cloud_color = vec3(1.0, 0.4, 0.2) * 2.0; // 高亮橘红
    //vec3 day_cloud_color = vec3(1.0, 1.0, 1.0);
    //
    //// 利用太阳的高度 (sun_direction.y) 来混合云的颜色
    //float sunset_factor = clamp(1.0 - (sun_direction.y * 3.0), 0.0, 1.0);
    //vec3 final_cloud_color = mix(day_cloud_color, sunset_cloud_color, sunset_factor);
    //
    //// 加一点太阳光晕的漫反射在云上 (让云遮住太阳时有透光感)
    //final_cloud_color += pow(max(0.0, sun_dot), 10.0) * sun_color * 0.5;
//
    //// ==========================================
    //// 最终混合
    //// ==========================================
    //// 将天空底色和云层按云的密度混合，最后再叠加超亮的太阳
    //vec3 final_sky = mix(sky_tonemapped, final_cloud_color, cloud_density);
    //
    //COLOR = final_sky + sun_total;
}