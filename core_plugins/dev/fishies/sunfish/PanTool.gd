extends WhiteboardTool

var is_dragging: bool = false
var drag_start_pos: Vector2
var last_mouse_pos: Vector2
var last_was_mag: bool = false


static func _static_init() -> void:
	WhiteboardManager.register_passive_tool(new())


static func get_id() -> StringName: return "dev.fishies.sunfish.PanTool"


static func is_visible() -> bool:
	return false


func receive_input(wb: Whiteboard, event: InputEvent) -> WhiteboardTool.Display:
	var cursor_shape: Control.CursorShape = Control.CURSOR_ARROW
	var mb := event as InputEventMouseButton
	if mb:
		var factor := mb.factor
		if mb.alt_pressed:
			factor *= 3.0
		match mb.button_index:
			MOUSE_BUTTON_MIDDLE:
				if mb.pressed:
					cursor_shape = Control.CURSOR_DRAG
				drag_start_pos = mb.position
				is_dragging = mb.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					if mb.ctrl_pressed:
						zoom(wb, mb.position, 1.0 * 1.1)
					else:
						pan(wb, factor, +00.0, +80.0)
					wb.accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					if mb.ctrl_pressed:
						zoom(wb, mb.position, 1.0 / 1.1)
					else:
						pan(wb, factor, +00.0, -80.0)
					wb.accept_event()
			MOUSE_BUTTON_WHEEL_LEFT:
				if mb.pressed:
					pan(wb, factor, +80.0, +00.0)
					wb.accept_event()
			MOUSE_BUTTON_WHEEL_RIGHT:
				if mb.pressed:
					pan(wb, factor, -80.0, +00.0)
					wb.accept_event()
	var mm := event as InputEventMouseMotion
	if mm and not wb.is_echoed_input:
		last_mouse_pos = mm.position
		if is_dragging:
			cursor_shape = Control.CURSOR_DRAG
			if mm.ctrl_pressed:
				zoom(wb, drag_start_pos, exp(- mm.relative.y * 0.005 * wb.draw_scale))
			else:
				wb.draw_xform = wb.draw_xform.translated_local(mm.relative)
			wb.accept_event()
	var pg := event as InputEventPanGesture
	if pg:
		var delta := pg.delta
		if pg.alt_pressed:
			delta *= 3.0
		if last_was_mag:
			delta = -delta * 0.1
		if pg.ctrl_pressed:
			zoom(wb, pg.position, exp(-delta.y * 0.1))
		else:
			wb.draw_xform = wb.draw_xform.translated(-delta * 4.0)
		wb.accept_event()
	var zg := event as InputEventMagnifyGesture
	if zg:
		last_was_mag = true
		set_deferred("last_was_mag", false)
		zoom(wb, zg.position, zg.factor)
	return Display.new().with_cursor_shape(cursor_shape)


func pan(wb: Whiteboard, factor: float, x: float, y: float) -> void:
	wb.draw_xform = wb.draw_xform.translated(0.5 * factor * Vector2(x, y))


func zoom(wb: Whiteboard, screen_center: Vector2, amount: float) -> void:
	var center := screen_center
	if amount < 1 and wb.draw_scale < 0.2:
		return
	wb.draw_xform = wb.draw_xform.translated_local(center).scaled_local(Vector2(amount, amount)).translated_local(-center)
