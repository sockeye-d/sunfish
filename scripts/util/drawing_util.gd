class_name DrawingUtil2


const CIRCLE_RESOLUTION = 90


static var rs := RenderingServer
static var quad_uvs: PackedVector2Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
static var tri_uvs: PackedVector2Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]
static var half_circle_tris: PackedVector2Array
static var half_circle_uvs: PackedVector2Array
static var half_circle_indices: PackedInt32Array


static func _static_init() -> void:
	half_circle_tris = [Vector2.ZERO]
	half_circle_uvs = [Vector2.ZERO]
	for angle_index in CIRCLE_RESOLUTION + 2:
		var angle := (angle_index) / float(CIRCLE_RESOLUTION) * PI - PI * 0.5
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
			var ca_norm := (a - c).normalized()
			var angle := ab_norm.angle_to(ca_norm)
			if ca_norm.dot(ab_norm) < 0.7:
				var normal_b := ca_norm.orthogonal()
				var normal_b_scaled := normal_b * half_width * a_width
				var normal_c := (ca_norm - ab_norm).normalized() * half_width * a_width
				if angle < 0.0:
					rs.canvas_item_add_primitive(canvas_item, [a, a + normal_c, a + normal_a], tri_colors, tri_uvs, RID())
					rs.canvas_item_add_primitive(canvas_item, [a, a + normal_c, a + normal_b_scaled], tri_colors, tri_uvs, RID())
				else:
					rs.canvas_item_add_primitive(canvas_item, [a, a + normal_c, a - normal_a], tri_colors, tri_uvs, RID())
					rs.canvas_item_add_primitive(canvas_item, [a, a + normal_c, a - normal_b_scaled], tri_colors, tri_uvs, RID())
			else:
				var b_normal = ca_norm.orthogonal() * half_width * a_width
				if angle < 0.0:
					rs.canvas_item_add_primitive(canvas_item, [a, a + b_normal, a + normal_a], tri_colors, tri_uvs, RID())
				else:
					rs.canvas_item_add_primitive(canvas_item, [a, a - b_normal, a - normal_a], tri_colors, tri_uvs, RID())
				
	var color_array := _create_color_array(half_circle_tris.size(), color)
	_add_endcap(canvas_item, points[0], points[1], color_array, width * pressures[0])
	_add_endcap(canvas_item, points[-1], points[-2], color_array, width * pressures[-1])


static func _add_endcap(canvas_item: RID, point_a: Vector2, point_b: Vector2, color: PackedColorArray, width: float) -> void:
	var start_angle := (point_a - point_b).normalized() * width * 0.5
	var rotated_half_circle_tris := Transform2D(start_angle, start_angle.orthogonal(), point_a) * half_circle_tris
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
