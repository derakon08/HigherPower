shader_type canvas_item;
uniform bool rotate_counter_clockwise = false;

void fragment(){
	if (rotate_counter_clockwise){
		COLOR = texture(TEXTURE, vec2(1.0 - UV.y, 1.0 - UV.x));
	
	} else { COLOR = texture(TEXTURE, vec2(UV.y, UV.x)); }
}
