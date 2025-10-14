class_name DrawingUtil


static var rs := RenderingServer
static var quad_uvs: PackedVector2Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
static var tri_uvs: PackedVector2Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]
static var half_circle_tris: PackedVector2Array
static var half_circle_uvs: PackedVector2Array
static var half_circle_indices: PackedInt32Array


static func _static_init() -> void:
	half_circle_tris = [Vector2.ZERO]
	half_circle_uvs = [Vector2.ZERO]
	for angle_index in 182:
		var angle := (angle_index) / 360.0 * TAU - PI * 0.5
		var point := Vector2.from_angle(angle)
		half_circle_tris.append(point)
		half_circle_uvs.append(Vector2.ZERO)
		if angle_index != 0:
			half_circle_indices.append_array([0, angle_index - 1, angle_index])


static func draw_round_polyline(canvas_item: RID, points: PackedVector2Array, color: Color, width: float, pressures: PackedFloat32Array = []) -> void:
	assert(points.size() >= 2)
	#color = Color(color, 0.25)
	var quad_colors: PackedColorArray = [color, color, color, color]
	#color = Color(Color.RED, 0.25)
	var tri_colors: PackedColorArray = [color, color, color]
	var half_width := width * 0.5
	for point_index in points.size() - 1:
		var a := points[point_index]
		var b := points[point_index + 1]
		var a_width := pressures[point_index] if pressures else 1.0
		var b_width := pressures[point_index + 1] if pressures else 1.0
		var ab := b - a
		var ab_norm := ab.normalized()
		var normal := ab_norm.orthogonal() * half_width
		var normal_a := normal * a_width
		rs.canvas_item_add_primitive(canvas_item, [a + normal_a, b + normal * b_width, b - normal * b_width, a - normal_a], quad_colors, quad_uvs, RID())
		if point_index > 0:
			var c := points[point_index - 1]
			var b_normal = (a - c).normalized().orthogonal() * half_width * a_width
			rs.canvas_item_add_primitive(canvas_item, [a, a + b_normal, a + normal_a], tri_colors, tri_uvs, RID())
			rs.canvas_item_add_primitive(canvas_item, [a, a - b_normal, a - normal_a], tri_colors, tri_uvs, RID())
	var color_array := _create_color_array(half_circle_tris.size(), color)
	_add_endcap(canvas_item, points[0], points[1], color_array, width * pressures[0])
	_add_endcap(canvas_item, points[-1], points[-2], color_array, width * pressures[-1])


static func _add_endcap(canvas_item: RID, point_a: Vector2, point_b: Vector2, color: PackedColorArray, width: float) -> void:
	var rotated_half_circle_tris := PackedVector2Array()
	rotated_half_circle_tris.resize(half_circle_tris.size())
	var start_angle := (point_a - point_b).angle()
	for i in half_circle_tris.size():
		rotated_half_circle_tris[i] = half_circle_tris[i].rotated(start_angle) * width * 0.5 + point_a
	rs.canvas_item_add_triangle_array(
		canvas_item,
		half_circle_indices,
		rotated_half_circle_tris,
		color,
		half_circle_uvs,
		[], [], RID()
	)


static func _create_color_array(length: int, color: Color) -> PackedColorArray:
	var arr := PackedColorArray()
	arr.resize(length)
	for i in length:
		arr[i] = color
	return arr
