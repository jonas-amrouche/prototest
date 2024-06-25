shader_type spatial;

uniform vec2 map_size;
uniform vec2 plane_size;
uniform sampler2D tri_texture;
uniform sampler2D grass_texture;
uniform vec2 grass_uv;
uniform sampler2D burned_texture;
uniform vec2 burned_uv;
uniform sampler2D pavement_texture;
uniform vec2 pavement_uv;
uniform float temp;
uniform float spec;
uniform float met;
uniform float rough;

void fragment() {
	vec3 tri_color = texture(tri_texture, UV/(map_size/plane_size) - ((1.0-(map_size/plane_size))/2.0)).rgb;
	vec3 pavement_color = texture(pavement_texture, UV*pavement_uv).rgb * tri_color.r;
	vec3 grass_color = texture(grass_texture, UV*grass_uv).rgb * tri_color.g;
	vec3 burned_color = texture(burned_texture, UV*burned_uv).rgb * tri_color.b;
	ALBEDO = grass_color + burned_color + pavement_color;
	ALBEDO *= temp;
	SPECULAR = spec;
	METALLIC = met;
	ROUGHNESS = rough;
}

vec2 coordinate_to_uv(vec2 coord){
	return coord/map_size-vec2(0.5);
}

vec2 uv_to_coordiante(vec2 uv){
	return uv-vec2(0.5)*map_size;
}