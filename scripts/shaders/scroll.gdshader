shader_type canvas_item;
uniform float scroll_speed;

void fragment() {
        // Called for every pixel the material is visible on.
        vec2 shifteduv = UV;
        shifteduv.y += TIME * scroll_speed;
        COLOR *= texture(TEXTURE, shifteduv);
}
