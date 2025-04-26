shader_type spatial;

uniform sampler2D tex1;
uniform float uv1 = 1.0;
uniform sampler2D tex2;
uniform float uv2 = 1.0;
uniform sampler2D tex3;
uniform float uv3 = 1.0;
uniform vec3 color : source_color;
uniform vec2 param1 = vec2(0.3, 0.2);
uniform vec2 param2 = vec2(0.4, 0.7);
uniform vec2 param3 = vec2(0.3, 0.1);
uniform float gitter_speed = 1.0;
uniform float gitter_force = 1.0;
uniform float intensity = 1.0;
uniform float highlight_intensity = 1.0;

uniform float distance_to_transi = 5.0;
uniform float fade_transi = 0.5;

void vertex() {
	COLOR.rgb = VERTEX;
}

void fragment()
{
    vec2 uv = UV;
    vec2 dist = vec2(0.0);
    dist += texture(tex2,fract(uv * uv2+vec2(TIME * gitter_speed*0.2,0.0))).rr * param1;
    dist += texture(tex2,fract(uv * uv2+vec2(TIME * gitter_speed*-0.1,TIME * gitter_speed*-0.1))).rr * param2;
    dist += texture(tex2,fract(uv * uv2+vec2(TIME * gitter_speed*-0.03,TIME * gitter_speed*0.2))).rr * param3;
    vec3 col = texture(tex1,uv * uv1 - dist * gitter_force * 0.02 * 1.).rgb * color;
    col += pow(dot(normalize(vec3(dist.x,1.0,dist.y)),vec3(0.0,1.0,0.0)),16.0) * highlight_intensity;
    ALBEDO = col * intensity;
	SPECULAR = 0.0;
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
	float mask_noise = texture(tex2, uv * uv2+vec2(TIME * gitter_speed*-0.03,TIME * gitter_speed*0.07)).r;
	float test = clamp((distance_to_transi - distance(COLOR.rb, vec2(0.0))) * fade_transi, 1.0, 2.0) * mask_noise;
	ALPHA = clamp((distance_to_transi - distance(COLOR.rb, vec2(0.0))) * fade_transi * test, 0.0, 1.0);
}