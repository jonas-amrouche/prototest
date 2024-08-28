shader_type spatial;
render_mode depth_test_disabled;

uniform sampler2D fog_texture;
uniform float uv_multiplier;
uniform vec2 uv_offset = vec2(0.5, -0.5);
uniform float blur_power = 1.0;
uniform int iter = 1;
uniform int quali = 1;

varying vec3 uv_power_normal;
varying vec2 uv_triplanar_pos;

void vertex(){
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	
	uv_power_normal = pow(abs(mat3(MODEL_MATRIX) * NORMAL), vec3(1.0));
	uv_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0f)).xz;
	uv_power_normal /= dot(uv_power_normal, vec3(1.0));
}

vec4 triplanar_texture_xorgaussian_2d(sampler2D tex, vec2 uv, vec2 pixel_size, float blurriness, int iterations, int quality){
	float pi = 6.28;
	
	vec2 radius = blurriness / (1.0 / pixel_size).xy;
	vec4 blurred_tex = texture(tex, uv);
	
	for(float d = 0.0; d < pi; d += pi / float(iterations)){
		for( float i = 1.0 / float(quality); i <= 1.0; i += 1.0 / float(quality) ){
			vec2 directions = uv + vec2(cos(d), sin(d)) * radius * i;
			blurred_tex += texture(tex, directions);
		}
	}
	blurred_tex /= float(quality) * float(iterations) + 1.0;
	
	return blurred_tex;
}

void fragment() {
	float fog = triplanar_texture_xorgaussian_2d(fog_texture, uv_triplanar_pos * uv_multiplier*0.1 + uv_offset, vec2(1.0), blur_power, iter, quali).r;
	
	ALPHA = clamp((fog-0.3)*2.0, 0.0, 0.5);
	
	//ALBEDO = texture(fog_texture, uv_triplanar_pos * uv_multiplier*0.1 + uv_offset).rgb;
	ALBEDO = vec3(0.0);
	//if (ALBEDO.r < 0.9){
		//ALPHA = 0.0;
	//}else{
		//ALBEDO.rgb = vec3(0.0);
		//ALPHA = 0.4;
	//}
}
