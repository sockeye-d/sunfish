extends WhiteboardTool


var width: float = 5.0
var color: Color

var is_drawing: bool
var last_draw_element: BrushElement
var preview := PlainPreviewElement.new()


static func get_id() -> String: return "dev.fishies.sunfish.BrushTool"


func receive_input(wb: Whiteboard, event: InputEvent) -> Display:
	width = 5.0 / wb.draw_scale
	color = wb.primary_color
	preview.width = width
	preview.color = color
	var display := Display.new([], [preview])
	var mb := event as InputEventMouseButton
	if mb:
		match mb.button_index:
			MOUSE_BUTTON_LEFT:
				is_drawing = mb.pressed
				if mb.pressed:
					last_draw_element = null
				if not mb.pressed:
					if last_draw_element:
						display.elements = [last_draw_element]
					else:
						var dot = BrushDotElement.new()
						dot.position = mb.position
						dot.color = color
						dot.width = width
						display.elements = [dot]
					last_draw_element = null
	var mm := event as InputEventMouseMotion
	if mm:
		var mm_pos := mm.position
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT and not mm.relative.is_zero_approx():
			if is_drawing:
				if last_draw_element == null:
					last_draw_element = BrushElement.new()
				var el := last_draw_element
				el.append_point(mm_pos)
				el.color = color
				el.width = width
				display.elements = [el]
		preview.position = mm.position
	return display


class BrushElement extends WhiteboardTool.Element:
	static func _static_init() -> void:
		WhiteboardTools.register_deserializer(BrushElement)
	
	var points: PackedVector2Array
	var color: Color
	var width: float
	
	var min_p: Vector2 = Vector2(+INF, +INF)
	var max_p: Vector2 = Vector2(-INF, -INF)
	
	static func get_id() -> String: return "dev.fishies.sunfish.BrushElement"
	
	func append_point(point: Vector2) -> void:
		min_p = min_p.min(point)
		max_p = max_p.max(point)
		if points.size() >= 2 and points[-2].distance_squared_to(point) < width * width:
			points[-1] = point
		else:
			points.append(point)
	
	
	func _falloff(x: float) -> float: return max(0.0, 2.0 - 1.0 / x if x <= 1.0 else x)
	
	func draw(wb: Whiteboard) -> void:
		var real_width := _falloff(width * wb.draw_scale) / wb.draw_scale
		if real_width < 0.0:
			return
		if points.size() >= 2:
			var real_points: PackedVector2Array
			real_points.resize(points.size() * 2)
			for i in points.size() - 1:
				wb.draw_circle(points[i], real_width * 0.5, color)
				real_points[i * 2] = points[i]
				real_points[i * 2 + 1] = points[i + 1]
			wb.draw_circle(points[-1], real_width * 0.5, color)
			wb.draw_multiline(real_points, color, real_width)
	
	
	func should_draw(at_pos: Vector2, threshold: float = width) -> bool:
		if points.is_empty():
			return false
		return points[-1].distance_squared_to(at_pos) > threshold * threshold
	
	func get_bounding_box() -> Rect2:
		return Rect2(min_p, max_p - min_p).grow(width).abs()
	
	func serialize() -> Dictionary:
		return {
			"points": points,
			"color": color,
			"width": width,
		}
	
	
	static func deserialize(data: Dictionary) -> Element:
		var el := BrushElement.new()
		el.points = data.points
		el.color = data.color
		el.width = data.width
		return el


class BrushDotElement extends WhiteboardTool.Element:
	static func _static_init() -> void:
		WhiteboardTools.register_deserializer(BrushDotElement)
	
	var position: Vector2
	var color: Color
	var width: float
	
	static func get_id() -> String: return "dev.fishies.sunfish.BrushDotElement"
	
	func draw(wb: Whiteboard) -> void:
		wb.draw_circle(position, width * 0.5, color)
	
	func get_bounding_box() -> Rect2:
		return Rect2(position, Vector2.ZERO).grow(width)
	
	
	func serialize() -> Dictionary:
		return {
			"position": position,
			"color": color,
			"width": width,
		}
	
	
	static func deserialize(data: Dictionary) -> Element:
		var el := BrushDotElement.new()
		el.position = data.position
		el.color = data.color
		el.width = data.width
		return el
