extends ShapeTool

const ShapeTool = preload("uid://ix2kr7fc4iy8")


static func get_id() -> StringName: return "dev.fishies.sunfish.FilledRectangleTool"


func create_element() -> ShapeElement:
	return FilledRectangleElement.new()


class FilledRectangleElement extends ShapeTool.ShapeElement:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(FilledRectangleElement)
	
	static func get_id() -> StringName: return "dev.fishies.sunfish.FilledRectangleElement"
	
	func _falloff(x: float) -> float: return max(0.0, 2.0 - 1.0 / x if x <= 1.0 else x)
	
	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void:
		var real_width := _falloff(width * wb.draw_scale) / wb.draw_scale
		if real_width < 0.0:
			return
		canvas.draw_circle(rect.position + rect.size * Vector2(0, 0), real_width * 0.5, color)
		canvas.draw_circle(rect.position + rect.size * Vector2(1, 0), real_width * 0.5, color)
		canvas.draw_circle(rect.position + rect.size * Vector2(0, 1), real_width * 0.5, color)
		canvas.draw_circle(rect.position + rect.size * Vector2(1, 1), real_width * 0.5, color)
		canvas.draw_rect(Rect2(
			rect.position - Vector2(real_width * 0.5, 0.0),
			rect.size + Vector2(real_width, 0.0)
		).abs(), color)
		canvas.draw_rect(Rect2(
			rect.position - Vector2(0.0, real_width * 0.5),
			rect.size + Vector2(0.0, real_width)
		).abs(), color)
	
	static func deserialize(data: Dictionary) -> Element: return deserialize_into(new(), data)
