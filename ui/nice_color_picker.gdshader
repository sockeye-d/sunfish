shader_type canvas_item;

#define SQRT_3 (1.732050807568877)
#define INV_SQRT_3 (0.5773502691896258)
#define TWO_OVER_SQRT_3 (1.154700538379252)
#define SQRT_3_OVER_3 (0.5773502691896258)

uniform vec3 hsv;
global uniform float ui_scale;

float donut(vec2 uv, float inner_radius, float outer_radius) {
	return abs(length(uv) - (inner_radius + outer_radius) * 0.5) - (outer_radius - inner_radius) * 0.5;
}

float triangle(vec2 uv, float r) {
    uv.x = abs(uv.x) - r;
    uv.y = uv.y + r / SQRT_3;
    if (uv.x + SQRT_3 * uv.y > 0.0) uv = vec2(uv.x - SQRT_3 * uv.y, -SQRT_3 * uv.x - uv.y) / 2.0;
    uv.x -= clamp(uv.x, -2.0 * r, 0.0);
    return -length(uv) * sign(uv.y);
}

float rectangle(vec2 uv, vec2 size) {
	vec2 d = abs(uv) - size;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float line(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

vec3 hsv2rgb(vec3 c) {
	const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 over(vec4 a, vec4 b) {
    float aOut = a.a + b.a * (1.0 - a.a);
    return vec4((a.rgb * a.a + b.rgb * b.a * (1.0 - a.a)) / max(0.0000000000000051, aOut), aOut);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

mat2 rot(float r) { return mat2(vec2(cos(r), -sin(r)), vec2(sin(r), cos(r))); }

void fragment() {
	float hue = hsv.r;
	float sat = hsv.g;
	float val = hsv.b;

	vec2 uv = (UV - 0.5) * 2.0;
	float pixel = dFdx(uv.x);
	float aa_pixel = pixel * 1.5;
	float ui_pixel = pixel * ui_scale;
	float donut_mask = smoothstep(aa_pixel, 0.0, donut(uv, 0.7, 1.0 - aa_pixel));
	vec2 square_size = vec2(0.7 - aa_pixel) * sqrt(0.5);
	mat2 rotation = rot((-hue - 0.125) * TAU);
	vec2 square_coords = (uv * rotation + square_size) / square_size * 0.5;
	float square_mask = smoothstep(aa_pixel, 0.0, rectangle(uv * rotation, square_size));
	COLOR = vec4(0);
	float uv_angle = atan(uv.y, uv.x) / TAU;
	COLOR = over(vec4(hsv2rgb(vec3(uv_angle, 1.0, 1.0)), donut_mask), COLOR);
	COLOR = over(vec4(hsv2rgb(vec3(hue, clamp(square_coords.x, 0.0, 1.0), clamp(1.0 - square_coords.y, 0.0, 1.0))), square_mask), COLOR);
	
	vec2 sv_handle_pos = (vec2(sat, 1.0 - val) * (square_size / 0.5) - square_size) * inverse(rotation);
	float sv_handle_mask_1 = smoothstep(aa_pixel, 0.0, donut(uv - sv_handle_pos, ui_pixel * 4.0, ui_pixel * 6.0));
	float sv_handle_mask_2 = smoothstep(aa_pixel, 0.0, donut(uv - sv_handle_pos, ui_pixel * 5.0, ui_pixel * 5.0));
	COLOR = over(vec4(vec3(1), sv_handle_mask_1), COLOR);
	COLOR = over(vec4(vec3(0), sv_handle_mask_2), COLOR);
	
	vec2 h_pos = vec2(cos(hue * TAU), sin(hue * TAU));
	float h_handle_sdf = line(uv, h_pos * (0.7 + ui_pixel * 2.0), h_pos * (1.0 - ui_pixel * 2.0));
	float h_handle_mask_1 = smoothstep(aa_pixel, 0.0, h_handle_sdf - ui_pixel * 2.0);
	float h_handle_mask_2 = smoothstep(aa_pixel, 0.0, h_handle_sdf - ui_pixel);
	COLOR = over(vec4(vec3(1), h_handle_mask_1), COLOR);
	COLOR = over(vec4(vec3(0), h_handle_mask_2), COLOR);
}
