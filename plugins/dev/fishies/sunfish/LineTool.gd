extends WhiteboardTool


@export_range(1.0, 5.0, 0.0, "or_greater") var width: float = 5.0
var color: Color

var is_drawing: bool
var last_draw_element: LineElement
var start_pos: Vector2
var preview := PlainPreviewElement.new()


static func get_id() -> String: return "dev.fishies.sunfish.LineTool"


func receive_input(wb: Whiteboard, event: InputEvent) -> Display:
	var draw_width := width / wb.draw_scale
	color = wb.primary_color
	preview.width = draw_width
	preview.color = color
	var display := Display.new([], [preview])
	var mb := event as InputEventMouseButton
	if mb:
		match mb.button_index:
			MOUSE_BUTTON_LEFT:
				if mb.pressed:
					start_pos = mb.position
					last_draw_element = LineElement.new()
					last_draw_element.color = color
					last_draw_element.width = draw_width
					last_draw_element.start_pos = mb.position
				else:
					last_draw_element = null
	var mm := event as InputEventMouseMotion
	if mm:
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT and not mm.relative.is_zero_approx():
			if last_draw_element:
				if mm.alt_pressed:
					start_pos += mm.relative
				var snapped_pos := mm.position
				if mm.ctrl_pressed:
					var delta := snapped_pos - start_pos
					snapped_pos = Vector2.from_angle(snappedf(delta.angle(), TAU / 16.0)) * delta.length() + start_pos
				last_draw_element.start_pos = start_pos
				last_draw_element.end_pos = snapped_pos
				display.elements = [last_draw_element]
		preview.position = mm.position
	return display


class LineElement extends WhiteboardTool.Element:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(LineElement)
	
	var color: Color
	var width: float
	
	var start_pos: Vector2
	var end_pos: Vector2
	
	static func get_id() -> String: return "dev.fishies.sunfish.LineElement"
	
	func _falloff(x: float) -> float: return max(0.0, 2.0 - 1.0 / x if x <= 1.0 else x)
	
	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void:
		var real_width := _falloff(width * wb.draw_scale) / wb.draw_scale
		if real_width < 0.0:
			return
		canvas.draw_circle(start_pos, real_width * 0.5, color)
		canvas.draw_line(start_pos, end_pos, color, width)
		canvas.draw_circle(end_pos, real_width * 0.5, color)
	
	func get_bounding_box() -> Rect2:
		return Rect2(start_pos, end_pos - start_pos).abs().grow(width)
	
	
	func serialize() -> Dictionary:
		return {
			"color": color,
			"width": width,
			"start_pos": start_pos,
			"end_pos": end_pos,
		}
	
	
	static func deserialize(data: Dictionary) -> Element:
		var el := LineElement.new()
		el.color = data.color
		el.width = data.width
		el.start_pos = data.start_pos
		el.end_pos = data.end_pos
		return el
