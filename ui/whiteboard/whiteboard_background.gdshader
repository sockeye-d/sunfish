shader_type canvas_item;

uniform mat3 xform;
uniform vec4 text_color;

global uniform float ui_scale;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 aspect = vec2(dFdxCoarse(UV.x), dFdyCoarse(UV.y));
	vec2 uv = (xform * vec3(UV / aspect / ui_scale, 1)).xy * 0.025;
	float pixel = dFdxCoarse(uv.x);
	float aa_pixel = pixel * 1.5;
	float ui_pixel = pixel * ui_scale;
	
	COLOR = vec4(
		text_color.rgb,
		smoothstep(aa_pixel, 0.0, length(fract(uv) - 0.5) - ui_pixel) * smoothstep(0.15, 0.03, pixel) * smoothstep(0.0015, 0.005, pixel) * 0.25
	);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
