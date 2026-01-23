shader_type canvas_item;

void vertex() {
	vec4 custom_data = INSTANCE_CUSTOM;
	UV = (custom_data.xy + UV) * custom_data.zw;
}