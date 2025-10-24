//
// Created by fish on 10/14/25.
//

#include "drawing_util.h"

#include <godot_cpp/classes/rendering_server.hpp>

using namespace godot;

#define CIRCLE_RESOLUTION 90

PackedColorArray DrawingUtil::create_color_array(const size_t p_length, const Color p_value) {
	PackedColorArray array;
	array.resize(p_length);
	for (size_t i = 0; i < p_length; i++) {
		array[i] = p_value;
	}
	return array;
}

DrawingUtil::HalfCircleData *DrawingUtil::generate_half_circle_data() {
	auto hd = new HalfCircleData;
	hd->half_circle_tris = {Vector2()};
	hd->half_circle_uvs = {Vector2()};
	for (int angle_index = 0; angle_index < CIRCLE_RESOLUTION + 2; angle_index++) {
		const auto angle = (angle_index) / static_cast<real_t>(CIRCLE_RESOLUTION) * Math_PI - Math_PI * 0.5;
		auto point = Vector2::from_angle(angle);
		hd->half_circle_tris.append(point);
		hd->half_circle_uvs.append(Vector2());
		if (angle_index != 0) {
			hd->half_circle_indices.append_array({0, angle_index - 1, angle_index});
		}
	}
	return hd;
}

void DrawingUtil::_bind_methods() {
	ClassDB::bind_static_method("DrawingUtil",
								D_METHOD("draw_round_polyline", "canvas_item", "points", "color", "width", "pressures"),
								&DrawingUtil::draw_round_polyline);
	ClassDB::bind_static_method("DrawingUtil", D_METHOD("merge_close_points", "points", "pressures", "min_dist"),
								&DrawingUtil::merge_close_points);
}

void DrawingUtil::draw_round_polyline(const RID& p_canvas_item, const PackedVector2Array& p_points, const Color p_color,
									  const double p_width, const PackedFloat32Array& p_pressures) {
	static PackedVector2Array quad_uvs = {Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)};
	static PackedVector2Array tri_uvs = {Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)};
	ERR_FAIL_COND(p_points.size() < 2);
	const auto point_count = p_points.size();
	PackedColorArray quad_colors = {p_color, p_color, p_color, p_color};
	PackedColorArray tri_colors = {p_color, p_color, p_color};
	double half_width = p_width / 2;
	auto rs = RenderingServer::get_singleton();
	for (int point_index = 0; point_index < point_count - 1; ++point_index) {
		auto a = p_points[point_index];
		auto b = p_points[point_index + 1];
		auto a_width = p_pressures.is_empty() ? 1.0 : p_pressures[point_index];
		auto b_width = p_pressures.is_empty() ? 1.0 : p_pressures[point_index + 1];
		auto ab = b - a;
		auto ab_norm = ab.normalized();
		auto normal = ab_norm.orthogonal() * half_width;
		auto normal_a = normal * a_width;
		rs->canvas_item_add_primitive(p_canvas_item,
									  {a + normal_a, b + normal * b_width, b - normal * b_width, a - normal_a},
									  quad_colors, quad_uvs, RID());
		if (point_index > 0) {
			auto c = p_points[point_index - 1];
			auto ca_norm = (a - c).normalized();
			auto angle = ab_norm.angle_to(ca_norm);
			if (ca_norm.dot(ab_norm) < 0.7) {
				auto normal_b = ca_norm.orthogonal();
				auto normal_b_scaled = normal_b * half_width * a_width;
				auto normal_c = (ca_norm - ab_norm).normalized() * half_width * a_width;
				if (angle < 0.0) {
					rs->canvas_item_add_primitive(p_canvas_item, {a, a + normal_c, a + normal_a}, tri_colors, tri_uvs,
												  RID());
					rs->canvas_item_add_primitive(p_canvas_item, {a, a + normal_c, a + normal_b_scaled}, tri_colors,
												  tri_uvs, RID());
				} else {
					rs->canvas_item_add_primitive(p_canvas_item, {a, a + normal_c, a - normal_a}, tri_colors, tri_uvs,
												  RID());
					rs->canvas_item_add_primitive(p_canvas_item, {a, a + normal_c, a - normal_b_scaled}, tri_colors,
												  tri_uvs, RID());
				}
			} else {
				auto b_normal = ca_norm.orthogonal() * half_width * a_width;
				if (angle < 0.0) {
					rs->canvas_item_add_primitive(p_canvas_item, {a, a + b_normal, a + normal_a}, tri_colors, tri_uvs,
												  RID());
				} else {
					rs->canvas_item_add_primitive(p_canvas_item, {a, a - b_normal, a - normal_a}, tri_colors, tri_uvs,
												  RID());
				}
			}
		}
	}
	draw_endcap(p_canvas_item, p_points[0], p_points[1], p_color, p_width * p_pressures[0]);
	draw_endcap(p_canvas_item, p_points[p_points.size() - 1], p_points[p_points.size() - 2], p_color,
				p_width * p_pressures[p_pressures.size() - 1]);
}

void DrawingUtil::draw_endcap(const RID& p_canvas_item, const Vector2 p_a, const Vector2 p_b, const Color p_color,
							  const double p_width) {
	static const auto* data = generate_half_circle_data();
	const PackedColorArray color_array = create_color_array(data->half_circle_tris.size(), p_color);
	const auto start_angle = (p_a - p_b).normalized() * p_width * 0.5;
	const auto rotated_half_circle_tris =
		Transform2D(start_angle, start_angle.orthogonal(), p_a).xform(data->half_circle_tris);
	RenderingServer::get_singleton()->canvas_item_add_triangle_array(
		p_canvas_item, data->half_circle_indices, rotated_half_circle_tris, color_array, data->half_circle_uvs, {}, {}, RID());
}

Array DrawingUtil::merge_close_points(const PackedVector2Array& p_points, const PackedFloat32Array& p_pressures,
									  const double p_min_dist) {
	PackedVector2Array real_points;
	PackedFloat32Array real_pressures;
	real_points.resize(p_points.size());
	real_pressures.resize(p_points.size());
	auto real_size = 0;
	Vector2 last_point = p_points[0];
	float_t average_pressure_sum = p_pressures[0];
	int average_pressure_count = 1;
	for (size_t i = 0; i < p_points.size() - 1; ++i) {
		if (last_point.distance_to(p_points[i]) < p_min_dist && i != 0) {
			average_pressure_sum += p_pressures[i];
			average_pressure_count++;
			continue;
		}
		real_points[real_size] = p_points[i];
		real_pressures[real_size++] = average_pressure_sum / average_pressure_count;
		last_point = p_points[i];
		average_pressure_sum = p_pressures[i];
		average_pressure_count = 1;
	}
	real_points[real_size] = p_points[p_points.size() - 1];
	real_pressures[real_size] = p_pressures[p_pressures.size() - 1];
	real_points.resize(real_size + 1);
	real_pressures.resize(real_size + 1);
	return {real_points, real_pressures};
}
