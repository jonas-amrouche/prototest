shader_type canvas_item;

uniform vec3 water_tint : source_color;
uniform sampler2D noise;
uniform float uv_noise_size = 0.8;

void fragment() {
	COLOR.a = 0.0;
	COLOR.rgb = water_tint;
	float n = texture(noise, UV * uv_noise_size + vec2(0.1, 0.1)).r;
	if (n > 0.55 && n < 0.65){
		COLOR.a = 0.7;
	}
}
