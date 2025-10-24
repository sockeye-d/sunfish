#ifndef SUNFISH_DRAWINGUTIL_H
#define SUNFISH_DRAWINGUTIL_H
#include <godot_cpp/classes/object.hpp>

class DrawingUtil : public godot::Object {
	GDCLASS(DrawingUtil, godot::Object);

	static const int CIRCLE_RESOLUTION = 90;

	struct HalfCircleData {
		godot::PackedVector2Array half_circle_tris;
		godot::PackedVector2Array half_circle_uvs;
		godot::PackedInt32Array half_circle_indices;
	};

	static godot::PackedColorArray create_color_array(const size_t p_length, const godot::Color p_value);

	static HalfCircleData *generate_half_circle_data();

protected:
	static void _bind_methods();

public:
	static void draw_round_polyline(const godot::RID& p_canvas_item, const godot::PackedVector2Array& p_points,
									godot::Color p_color, double p_width, const godot::PackedFloat32Array& p_pressures);
	static void draw_endcap(const godot::RID& p_canvas_item, godot::Vector2 p_a, godot::Vector2 p_b,
							godot::Color p_color, double p_width);
	static godot::Array merge_close_points(const godot::PackedVector2Array& p_points,
														const godot::PackedFloat32Array& p_pressures,
														double p_min_dist);
};

#endif // SUNFISH_DRAWINGUTIL_H
