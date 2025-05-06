shader_type spatial;
//render_mode depth_draw_always;

uniform sampler2D noise_texture;
uniform float noise_uv = 1.0;
uniform sampler2D soil_texture;
uniform float soil_luminosity = 1.0;
uniform float soil_uv = 1.0;
uniform sampler2D dirt_texture;
uniform float dirt_luminosity = 1.0;
uniform float dirt_uv = 1.0;

//void vertex() {
	//COLOR.rgb = VERTEX;
//}

void fragment() {
	float noise = texture(noise_texture, UV * noise_uv).r;
	vec3 soil = texture(soil_texture, UV * soil_uv).rgb * soil_luminosity;
	vec3 dirt = texture(dirt_texture, UV * dirt_uv).rgb * dirt_luminosity;
	ALBEDO = mix(soil, dirt, noise);
	SPECULAR = 0.13;
	//METALLIC = 0.0;
	//ROUGHNESS = 1.0;
}