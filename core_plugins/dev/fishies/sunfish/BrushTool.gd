extends WhiteboardTool


@export_range(1.0, 5.0, 0.0, "or_greater") var width: float = _get_default_width()
var color: Color

var is_drawing: bool
var last_draw_element: BrushElement
var preview := PlainPreviewElement.new()


static func get_id() -> StringName: return "dev.fishies.sunfish.BrushTool"


static func get_shortcut() -> InputEvent: return Shortcuts.key(KEY_B)


func should_hide_mouse() -> bool: return true


func create_brush_element() -> BrushElement: return BrushElement.new()
func create_dot_element() -> BrushDotElement: return BrushDotElement.new()


func _get_default_width() -> float: return 5.0
func _do_pressure() -> bool: return true


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
				is_drawing = mb.pressed
				if mb.pressed:
					last_draw_element = null
				if not mb.pressed:
					if last_draw_element:
						display.elements = [last_draw_element]
					else:
						var dot = create_dot_element()
						dot.position = mb.position
						dot.color = color
						dot.width = draw_width
						display.elements = [dot]
					last_draw_element = null
	var mm := event as InputEventMouseMotion
	if mm:
		var mm_pos := mm.position
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT and not mm.relative.is_zero_approx():
			if is_drawing:
				if last_draw_element == null:
					last_draw_element = create_brush_element()
				var el := last_draw_element
				el.append_point(mm_pos, (mm.pressure if mm.pressure > 0.0 else 1.0) if _do_pressure() else 1.0, wb)
				el.color = color
				el.width = draw_width
				display.elements = [el]
		preview.position = mm.position
	return display


class BrushElement extends WhiteboardTool.Element:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(BrushElement)

	var points: PackedVector2Array
	var pressures: PackedFloat32Array
	var color: Color
	var width: float

	var min_p: Vector2 = Vector2(+INF, +INF)
	var max_p: Vector2 = Vector2(-INF, -INF)

	static func get_id() -> StringName: return "dev.fishies.sunfish.BrushElement"

	func append_point(point: Vector2, pressure: float, wb: Whiteboard) -> void:
		min_p = min_p.min(point)
		max_p = max_p.max(point)
		var tolerance := 3.0 / wb.draw_scale
		if DebugManager.giant_brush_deadzone:
			tolerance *= 10.0
		tolerance *= tolerance
		if points.size() >= 2 and points[-2].distance_squared_to(point) < tolerance:
			points[-1] = point
			pressures[-1] = pressure
		else:
			points.append(point)
			pressures.append(pressure)


	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void:
		Util.unused(wb)
		if points.size() >= 2:
			DrawingUtil.draw_round_polyline(canvas.get_canvas_item(), points, color, width, pressures)


	func get_bounding_box() -> Rect2:
		return Rect2(min_p, max_p - min_p).grow(width * 0.5).abs()

	func serialize() -> Dictionary:
		return {
			"points": points,
			"pressures": pressures,
			"color": color,
			"width": width,
		}


	static func deserialize(data: Dictionary) -> Element:
		var el := BrushElement.new()
		_deserialize(el, data)
		return el


	static func _deserialize(el: BrushElement, data: Dictionary) -> void:
		el.points = data.points
		el.pressures = data.get("pressures", [])
		if el.pressures.size() != el.points.size():
			var old_size := el.pressures.size()
			el.pressures.resize(el.points.size())
			for i in range(old_size, el.pressures.size()):
				el.pressures[i] = 1.0
		el.color = data.color
		el.width = data.width
		var new_min_p: Vector2 = Vector2(+INF, +INF)
		var new_max_p: Vector2 = Vector2(-INF, -INF)
		for point in el.points:
			new_min_p = new_min_p.min(point)
			new_max_p = new_max_p.max(point)
		el.min_p = new_min_p
		el.max_p = new_max_p


class BrushDotElement extends WhiteboardTool.Element:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(BrushDotElement)

	var position: Vector2
	var color: Color
	var width: float

	static func get_id() -> StringName: return "dev.fishies.sunfish.BrushDotElement"

	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void:
		Util.unused(wb)
		canvas.draw_circle(position, width * 0.5, color)

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
		_deserialize(el, data)
		return el


	static func _deserialize(el: BrushDotElement, data: Dictionary) -> void:
		el.position = data.position
		el.color = data.color
		el.width = data.width
