shader_type canvas_item;

uniform sampler2D canvas_texture;

void fragment() {
	vec4 color = texture(canvas_texture, UV);
	COLOR = vec4(color.rgb / color.a, color.a);
}