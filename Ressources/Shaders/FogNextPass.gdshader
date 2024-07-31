shader_type spatial;

uniform sampler2D fog_texture;
uniform float uv_multiplier;
uniform vec3 uv_offset;

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}

varying vec3 uv_power_normal;
varying vec3 uv_triplanar_pos;

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
	uv_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0f)).xyz;
	uv_power_normal /= dot(uv_power_normal, vec3(1.0));
	uv_triplanar_pos *= vec3(1.0, -1.0, 1.0);
	COLOR.rg = VERTEX.xz;
}

vec4 triplanar_texture_2d(sampler2D p_sampler,vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xz);
	return samp;
}

void fragment() {
	ALBEDO = triplanar_texture_2d(fog_texture, uv_triplanar_pos * uv_multiplier*0.1 + uv_offset).rgb;
	if (ALBEDO.r < 0.9){
		ALPHA = 0.0;
	}else{
		ALBEDO.rgb = vec3(0.0);
		ALPHA = 1.0;
	}
}
