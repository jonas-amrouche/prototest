shader_type canvas_item;

uniform bool filled = false;
uniform sampler2D noise1 : repeat_enable;
uniform float decay;
uniform sampler2D shine;
uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;

void fragment() {
	if (filled){
		COLOR += texture(shine, UV) * (COLOR.a *-1.0 +1.0) * 0.3;
		COLOR *= texture(noise1, UV*0.1 + (vec2(0.01, -0.015) * (TIME + decay))) * color1 * 1.0;
		COLOR /= texture(noise1, UV*0.1 + (vec2(-0.012, 0.01) * (TIME + decay))) * color2 * 1.0;
		//COLOR /= 1.0 * texture(noise2, UV*0.2 + (vec2(-0.01, 0.02) * TIME)) * color2;
	}else{
		COLOR = min(COLOR * 2.0, vec4(1.0));
		COLOR *= vec4(vec3(0.1), 0.9);
	}
}
