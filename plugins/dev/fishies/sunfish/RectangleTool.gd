extends ShapeTool

const ShapeTool = preload("uid://ix2kr7fc4iy8")


static func get_id() -> String: return "dev.fishies.sunfish.RectangleTool"


func create_element() -> ShapeElement:
	return RectangleElement.new()


class RectangleElement extends ShapeTool.ShapeElement:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(RectangleElement)
	
	static func get_id() -> String: return "dev.fishies.sunfish.RectangleElement"
	
	func _falloff(x: float) -> float: return max(0.0, 2.0 - 1.0 / x if x <= 1.0 else x)
	
	func draw(wb: Whiteboard) -> void:
		var real_width := _falloff(width * wb.draw_scale) / wb.draw_scale
		if real_width < 0.0:
			return
		var p_tl := rect.position + rect.size * Vector2(0, 0)
		var p_tr := rect.position + rect.size * Vector2(1, 0)
		var p_bl := rect.position + rect.size * Vector2(0, 1)
		var p_br := rect.position + rect.size * Vector2(1, 1)
		wb.draw_circle(p_tl, real_width * 0.5, color)
		wb.draw_circle(p_tr, real_width * 0.5, color)
		wb.draw_circle(p_bl, real_width * 0.5, color)
		wb.draw_circle(p_br, real_width * 0.5, color)
		wb.draw_line(p_tl, p_tr, color, width)
		wb.draw_line(p_tr, p_br, color, width)
		wb.draw_line(p_br, p_bl, color, width)
		wb.draw_line(p_bl, p_tl, color, width)
	
	static func deserialize(data: Dictionary) -> Element: return deserialize_into(new(), data)
