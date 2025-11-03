extends ShapeTool

const ShapeTool = preload("uid://ix2kr7fc4iy8")


static func get_id() -> StringName: return "dev.fishies.sunfish.FilledRectangleTool"


func create_element() -> ShapeElement:
	return FilledRectangleElement.new()


class FilledRectangleElement extends ShapeTool.ShapeElement:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(FilledRectangleElement)
	
	static func get_id() -> StringName: return "dev.fishies.sunfish.FilledRectangleElement"
	
	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void:
		Util.unused(wb)
		var abs_rect := rect.abs()
		var rect_pos := abs_rect.position
		var rect_size := abs_rect.size
		canvas.draw_circle(rect_pos + rect_size * Vector2(0, 0), width * 0.5, color)
		canvas.draw_circle(rect_pos + rect_size * Vector2(1, 0), width * 0.5, color)
		canvas.draw_circle(rect_pos + rect_size * Vector2(0, 1), width * 0.5, color)
		canvas.draw_circle(rect_pos + rect_size * Vector2(1, 1), width * 0.5, color)
		canvas.draw_rect(Rect2(
			rect_pos - Vector2(width * 0.5, 0.0),
			rect_size + Vector2(width, 0.0)
		).abs(), color)
		canvas.draw_rect(Rect2(
			rect_pos - Vector2(0.0, width * 0.5),
			rect_size + Vector2(0.0, width)
		).abs(), color)
	
	static func deserialize(data: Dictionary) -> Element: return deserialize_into(new(), data)
