shader_type spatial;
render_mode depth_test_disabled;

uniform sampler2D fog_texture;
uniform sampler2D fog_texture_prev;
uniform float     fog_fade_t    : hint_range(0.0, 1.0) = 1.0;

uniform float uv_multiplier  = 0.0375;
uniform vec2  uv_offset      = vec2(0.5, -0.5);
uniform float blur_power     = 1.0;
uniform int   iter           = 1;
uniform int   quali          = 1;
uniform float transparency   = 0.5;

varying vec3 uv_power_normal;
varying vec2 uv_triplanar_pos;

void vertex() {
	TANGENT  = vec3(0.0, 0.0, -1.0) * abs(NORMAL.x);
	TANGENT  += vec3(1.0, 0.0,  0.0) * abs(NORMAL.y);
	TANGENT  += vec3(1.0, 0.0,  0.0) * abs(NORMAL.z);
	TANGENT  = normalize(TANGENT);

	BINORMAL  = vec3(0.0,  1.0,  0.0) * abs(NORMAL.x);
	BINORMAL += vec3(0.0,  0.0, -1.0) * abs(NORMAL.y);
	BINORMAL += vec3(0.0,  1.0,  0.0) * abs(NORMAL.z);
	BINORMAL  = normalize(BINORMAL);

	uv_power_normal  = pow(abs(mat3(MODEL_MATRIX) * NORMAL), vec3(1.0));
	uv_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	uv_power_normal /= dot(uv_power_normal, vec3(1.0));
}

vec4 gaussian_blur(sampler2D tex, vec2 uv, vec2 pixel_size, float blurriness, int iterations, int quality) {
	float pi     = 6.28318;
	vec2  radius = blurriness / (1.0 / pixel_size).xy;
	vec4  result = texture(tex, uv);

	for (float d = 0.0; d < pi; d += pi / float(iterations)) {
		for (float i = 1.0 / float(quality); i <= 1.0; i += 1.0 / float(quality)) {
			result += texture(tex, uv + vec2(cos(d), sin(d)) * radius * i);
		}
	}
	result /= float(quality) * float(iterations) + 1.0;
	return result;
}

void fragment() {
	vec2 uv = uv_triplanar_pos * uv_multiplier * 0.1 + uv_offset;
	vec2 px = vec2(1.0);

	// Sample both fog states
	float fog_curr = gaussian_blur(fog_texture,      uv, px, blur_power, iter, quali).r;
	float fog_prev = gaussian_blur(fog_texture_prev, uv, px, blur_power, iter, quali).r;

	// Lerp between previous and current — this is the fade that was in GDScript
	float fog = mix(fog_prev, fog_curr, fog_fade_t);

	ALBEDO = vec3(0.0);
	ALPHA  = clamp((fog - 0.3) * 2.0, 0.0, transparency);
}
