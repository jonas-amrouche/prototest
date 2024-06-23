shader_type canvas_item;

uniform float base_fog_size;
uniform float player_fog_size;
uniform vec2 base1_pos;
uniform vec2 base2_pos;
uniform vec2 player_pos;

void fragment() {
	if (COLOR.r < 0.9){
		COLOR.a = 0.5;
	}else{
		COLOR.a = 1.0;
	}
	if (distance(UV, player_pos) < player_fog_size || distance(UV, base1_pos) < base_fog_size || distance(UV, base2_pos) < base_fog_size){
		COLOR.a = 0.0;
	}
		
	COLOR.rgb = vec3(0.0074);
}
