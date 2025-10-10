extends ShapeTool

const ShapeTool = preload("uid://ix2kr7fc4iy8")


static func get_id() -> String: return "dev.fishies.sunfish.FilledRectangleTool"


func create_element() -> ShapeElement:
	return FilledRectangleElement.new()


class FilledRectangleElement extends ShapeTool.ShapeElement:
	static func get_id() -> String: return "dev.fishies.sunfish.FilledRectangleElement"
	
	func _falloff(x: float) -> float: return max(0.0, 2.0 - 1.0 / x if x <= 1.0 else x)
	
	func draw(wb: Whiteboard) -> void:
		var real_width := _falloff(width * wb.draw_scale) / wb.draw_scale
		if real_width < 0.0:
			return
		wb.draw_circle(rect.position + rect.size * Vector2(0, 0), real_width * 0.5, color)
		wb.draw_circle(rect.position + rect.size * Vector2(1, 0), real_width * 0.5, color)
		wb.draw_circle(rect.position + rect.size * Vector2(0, 1), real_width * 0.5, color)
		wb.draw_circle(rect.position + rect.size * Vector2(1, 1), real_width * 0.5, color)
		wb.draw_rect(Rect2(
			rect.position - Vector2(real_width * 0.5, 0.0),
			rect.size + Vector2(real_width, 0.0)
		), color)
		wb.draw_rect(Rect2(
			rect.position - Vector2(0.0, real_width * 0.5),
			rect.size + Vector2(0.0, real_width)
		), color)
