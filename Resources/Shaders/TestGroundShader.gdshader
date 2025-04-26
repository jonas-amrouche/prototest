shader_type spatial;

uniform sampler2D water_texture;
uniform sampler2D water_normal_texture;
uniform vec3 water_tint_1 : source_color;
uniform vec3 water_tint_2 : source_color;
uniform vec3 border_tint : source_color;
uniform sampler2D noise;
uniform float uv_noise_size = 1.0;
uniform float uv_water_size = 1.0;
uniform float uv_water_normal_size = 1.0;
uniform float texture_speed = 1.0;
uniform float normal_speed = 1.0;

void fragment() {
	ALPHA = 0.0;
	ALBEDO = mix(water_tint_1, water_tint_2, texture(water_texture, UV * uv_water_size + TIME * texture_speed).r);
	float n = texture(noise, UV * uv_noise_size).r;
	if (n > 0.5 && n < 0.7){
		ALPHA = min(1.0, abs((n-0.6)*10.0)*-2.0+2.0);
	}
	ALBEDO = mix(ALBEDO, border_tint, (min(1.0, abs((n-0.6)*10.0)*-2.0+2.0)*-1.0+1.0)*texture(water_texture, UV * uv_water_size + TIME * vec2(1.2, -1.3) * texture_speed).r);
	NORMAL_MAP = texture(water_normal_texture, UV * uv_water_normal_size + TIME * vec2(0.5, -0.3) * normal_speed).rgb;
	ROUGHNESS = 0.9;
}
