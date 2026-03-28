shader_type spatial;

uniform vec3 water_color : source_color = vec3(0.01, 0.03, 0.05); // deep blue
uniform float roughness : hint_range(0.0, 1.0) = 0.05;

void vertex() {
    float wave = 3.0 * sin(VERTEX.x * 0.5 + TIME) * 0.2 + 5.0 * cos(VERTEX.z * 0.5 + TIME) * 0.2;
    VERTEX.y += wave;
}

void fragment() {
    ALBEDO = water_color;
    
    METALLIC = 0.0;
    ROUGHNESS = roughness;
    SPECULAR = 0.5;
    
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), 5.0);
    
    ROUGHNESS = mix(roughness, 0.0, fresnel);
}