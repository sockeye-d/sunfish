@abstract
extends WhiteboardTool


@export_range(1.0, 5.0, 0.0, "or_greater") var width: float = 5.0
var color: Color

var is_drawing: bool
var last_draw_element: ShapeElement
var start_pos: Vector2
var preview := LinePreviewElement.new()


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
				if mb.pressed:
					start_pos = mb.position
					last_draw_element = create_element()
					last_draw_element.color = color
					last_draw_element.width = width
				else:
					last_draw_element = null
	var mm := event as InputEventMouseMotion
	if mm:
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT and not mm.relative.is_zero_approx():
			if last_draw_element:
				if mm.alt_pressed:
					start_pos += mm.relative
				var pos := start_pos
				var size := mm.position - start_pos
				if mm.shift_pressed:
					size = VectorUtil.max2(size.abs()) * size.sign()
				if mm.ctrl_pressed:
					pos -= size
					size *= 2.0
				
				last_draw_element.rect.position = pos
				last_draw_element.rect.size = size
				display.elements = [last_draw_element]
		preview.position = mm.position
	return display


@abstract
func create_element() -> ShapeElement


class LinePreviewElement extends WhiteboardTool.PreviewElement:
	var position: Vector2
	var color: Color
	var width: float
	
	func draw(canvas: CanvasItem, _wb: Whiteboard):
		canvas.draw_circle(position, width * 0.5, color, false, -2.0, false)


@abstract
class ShapeElement extends WhiteboardTool.Element:
	var color: Color
	var width: float
	
	var rect: Rect2
	
	func _falloff(x: float) -> float: return max(0.0, 2.0 - 1.0 / x if x <= 1.0 else x)
	
	func get_bounding_box() -> Rect2:
		return rect.abs().grow(width)
	
	
	func serialize() -> Dictionary:
		return {
			"color": color,
			"width": width,
			"rect": rect,
		}
	
	
	static func deserialize(data: Dictionary) -> Element:
		Util.unused(data)
		return null
	
	static func deserialize_into(instance: ShapeElement, data: Dictionary) -> ShapeElement:
		instance.rect = data.rect
		instance.color = data.color
		instance.width = data.width
		return instance
