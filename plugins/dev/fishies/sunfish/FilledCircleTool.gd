extends ShapeTool

const ShapeTool = preload("uid://ix2kr7fc4iy8")


static func get_id() -> StringName: return "dev.fishies.sunfish.FilledCircleTool"


func create_element() -> ShapeElement:
	return FilledCircleElement.new()


class FilledCircleElement extends ShapeTool.ShapeElement:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(FilledCircleElement)
	
	static func get_id() -> StringName: return "dev.fishies.sunfish.FilledCircleElement"
	
	func _falloff(x: float) -> float: return max(0.0, 2.0 - 1.0 / x if x <= 1.0 else x)
	
	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void:
		var real_width := _falloff(width * wb.draw_scale) / wb.draw_scale
		if real_width < 0.0:
			return
		var size := rect.size * 0.5
		var points: PackedVector2Array = []
		points.resize(180)
		var index_to_angle := TAU / points.size()
		for point_index in points.size():
			points[point_index] = Vector2.from_angle(point_index * index_to_angle) * size + rect.position + size
		points.append(points[0])
		canvas.draw_polyline(points, color, width)
		canvas.draw_colored_polygon(points, color)
	
	static func deserialize(data: Dictionary) -> Element: return deserialize_into(new(), data)
