shader_type spatial;

uniform vec3 albedo : source_color = vec3(0.01, 0.05, 0.1);
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float normal_scale = 2.0;

uniform sampler2D wave_texture : hint_normal;

uniform vec2 scroll1 = vec2(0.02, 0.02);
uniform vec2 scroll2 = vec2(-0.01, 0.03);

void fragment() {
    ALBEDO = albedo;
    ROUGHNESS = roughness;
    METALLIC = 0.0; // water is not metal

    vec2 uv_1 = UV * 20.0 + TIME * scroll1;
    vec2 uv_2 = UV * 20.0 + TIME * scroll2;

    vec3 n1 = texture(wave_texture, uv_1).rgb;
    vec3 n2 = texture(wave_texture, uv_2).rgb;

    vec3 normal_blend = mix(n1, n2, 0.5);

    NORMAL_MAP = normal_blend;
    NORMAL_MAP_DEPTH = normal_scale;
}