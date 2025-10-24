shader_type canvas_item;

uniform sampler2D canvas_texture;
global uniform float ui_scale;

void fragment() {
	COLOR = texture(canvas_texture, UV * ui_scale);
	COLOR.rgb /= COLOR.a;
}