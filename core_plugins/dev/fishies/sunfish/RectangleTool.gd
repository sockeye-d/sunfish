extends ShapeTool

const ShapeTool = preload("uid://ix2kr7fc4iy8")


static func get_id() -> StringName: return "dev.fishies.sunfish.RectangleTool"


func create_element() -> ShapeElement:
	return RectangleElement.new()


class RectangleElement extends ShapeTool.ShapeElement:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(RectangleElement)
	
	static func get_id() -> StringName: return "dev.fishies.sunfish.RectangleElement"
	
	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void:
		Util.unused(wb)
		var p_tl := rect.position + rect.size * Vector2(0, 0)
		var p_tr := rect.position + rect.size * Vector2(1, 0)
		var p_bl := rect.position + rect.size * Vector2(0, 1)
		var p_br := rect.position + rect.size * Vector2(1, 1)
		canvas.draw_circle(p_tl, width * 0.5, color)
		canvas.draw_circle(p_tr, width * 0.5, color)
		canvas.draw_circle(p_bl, width * 0.5, color)
		canvas.draw_circle(p_br, width * 0.5, color)
		canvas.draw_line(p_tl, p_tr, color, width)
		canvas.draw_line(p_tr, p_br, color, width)
		canvas.draw_line(p_br, p_bl, color, width)
		canvas.draw_line(p_bl, p_tl, color, width)
	
	static func deserialize(data: Dictionary) -> Element: return deserialize_into(new(), data)
