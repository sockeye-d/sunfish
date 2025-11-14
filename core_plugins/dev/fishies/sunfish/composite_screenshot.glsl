#[compute]
#version 450

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
layout(rgba8, binding = 0) restrict uniform image2D input_texture;
layout(rgba8, binding = 1) restrict uniform image2D output_texture;

layout(set = 0, binding = 2, std140) readonly uniform BGColor { vec3 bg_color; };

void main() {
	ivec2 coords = ivec2(gl_GlobalInvocationID.xy);
	vec4 src_color = imageLoad(input_texture, coords);
	// src_color here is premultiplied alpha. for some reason.
	imageStore(output_texture, coords, vec4(bg_color * (1.0 - src_color.a) + src_color.rgb, 1.0));
}
