shader_type spatial;
render_mode cull_disabled;

uniform sampler2D fire_texture_1;
uniform sampler2D fire_topfade_texture_1;
uniform float flame_speed;
uniform float flame_size = 1.0;
uniform float emission;
uniform vec4 color : source_color;

void vertex() {
	VERTEX.xy = VERTEX.xy + sin(TIME * flame_speed)*0.04 * NORMAL.yz * flame_size;
}

void fragment() {
	ALBEDO = texture(fire_texture_1, UV + vec2(0.0, 1.0) * TIME * flame_speed).rgb;
	EMISSION = texture(fire_texture_1, UV + vec2(0.0, 1.0) * TIME * flame_speed).rgb * emission * texture(fire_texture_1, UV + vec2(0.0, 1.0) * TIME * flame_speed).r * color.rgb;
	ALPHA = texture(fire_texture_1, UV + vec2(0.0, 1.0) * TIME * flame_speed).a;
	ALPHA *= clamp(0.0, 1.0, texture(fire_topfade_texture_1, UV + vec2(0.0, 0.1) * TIME * flame_speed*5.0 + vec2(1.0, 0.0) * sin(TIME * flame_speed * 10.0)*0.01).a*4.0*-1.0+1.0);
	ALPHA *= 0.5;
	//ALPHA_SCISSOR_THRESHOLD = 0.5;
}