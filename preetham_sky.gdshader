shader_type sky;

// sun_direction
uniform vec3 sun_direction;

uniform float theta_s;

// 5 set of parameters
uniform vec3 perez_A;
uniform vec3 perez_B;
uniform vec3 perez_C;
uniform vec3 perez_D;
uniform vec3 perez_E;

// set of zenith values
uniform vec3 zenith_Yxy;

vec3 Yxy_to_RGB(vec3 Yxy)
{
	float Y = Yxy.x;
    float x = Yxy.y;
    float y = max(Yxy.z, 0.0001); // 防止除以零
    
    float X = (x * Y) / y;
    float Z = ((1.0 - x - y) * Y) / y;
    vec3 XYZ = vec3(X, Y, Z);
    
    vec3 rgb;
    rgb.r =  3.240479 * XYZ.x - 1.537150 * XYZ.y - 0.498535 * XYZ.z;
    rgb.g = -0.969256 * XYZ.x + 1.875991 * XYZ.y + 0.041556 * XYZ.z;
    rgb.b =  0.055648 * XYZ.x - 0.204043 * XYZ.y + 1.057311 * XYZ.z;
    
    return rgb;
}

vec3 calc_perez(float theta, float gamma) {
    // F(theta, gamma) = (1 + A * e^(B/cos(theta))) * (1 + C * e^(D*gamma) + E * cos^2(gamma))
    vec3 term1 = 1.0 + perez_A * exp(perez_B / cos(theta));
    vec3 term2 = 1.0 + perez_C * exp(perez_D * gamma) + perez_E * cos(gamma) * cos(gamma);
    return term1 * term2;
}

void sky() {
	vec3 view_dir = normalize(EYEDIR);
    
    // calculate theta
    float theta = acos(max(view_dir.y, 0.001)); 
    
    // calculate gamma
    float gamma = acos(clamp(dot(view_dir, sun_direction), -1.0, 1.0));
        
    // Using equation 4 to calculate Y, x, y for current pixel
    // Y = Y_z * ( F(theta, gamma) / F(0, theta_s) )
    vec3 f_theta_gamma = calc_perez(theta, gamma);
    vec3 f_zero_theta_s = calc_perez(0.0, theta_s);
	// at zenith theta = 0 
    
    // current xyY value
    vec3 current_Yxy = zenith_Yxy * (f_theta_gamma / f_zero_theta_s);
    
    // Switch to RGB
    vec3 rgb_color = Yxy_to_RGB(current_Yxy);
    
    // multiply by a small coefficient
    COLOR = rgb_color * 0.05;
}
