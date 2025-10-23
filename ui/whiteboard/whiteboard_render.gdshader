shader_type canvas_item;

uniform sampler2D canvas_texture;
global uniform float ui_scale;

void fragment() {
	vec4 color = texture(canvas_texture, UV * ui_scale);
	COLOR = vec4(color.rgb / color.a, color.a);
}