extends WhiteboardTool

var is_dragging: bool = false
var drag_start_pos: Vector2

static func get_id() -> String: return "dev.fishies.sunfish.PanTool"


static func is_visible() -> bool:
	return false


func receive_input(wb: Whiteboard, event: InputEvent) -> WhiteboardTool.Display:
	if event.is_action_pressed("reset_zoom"):
		wb.draw_xform = Transform2D()
		wb.accept_event()
	var mb := event as InputEventMouseButton
	if mb:
		match mb.button_index:
			MOUSE_BUTTON_MIDDLE:
				wb.mouse_default_cursor_shape = Control.CURSOR_DRAG if mb.pressed else Control.CURSOR_ARROW
				drag_start_pos = mb.position
				is_dragging = mb.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					if mb.ctrl_pressed:
						wb.draw_xform = zoom(wb.draw_xform, mb.position, 1.0 * 1.1)
					else:
						pan(wb, mb, +00.0, +20.0)
					wb.accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					if mb.ctrl_pressed:
						wb.draw_xform = zoom(wb.draw_xform, mb.position, 1.0 / 1.1)
					else:
						pan(wb, mb, +00.0, -20.0)
					wb.accept_event()
			MOUSE_BUTTON_WHEEL_LEFT:
				if mb.pressed:
					pan(wb, mb, +20.0, +00.0)
					wb.accept_event()
			MOUSE_BUTTON_WHEEL_RIGHT:
				if mb.pressed:
					pan(wb, mb, -20.0, +00.0)
					wb.accept_event()
	var mm := event as InputEventMouseMotion
	if mm:
		if is_dragging:
			if mm.ctrl_pressed:
				wb.draw_xform = zoom(wb.draw_xform, drag_start_pos, exp(- mm.relative.y * 0.005 * wb.draw_scale))
			else:
				wb.draw_xform = wb.draw_xform.translated_local(mm.relative)
				wb.redraw_all()
			wb.accept_event()
	var pg := event as InputEventPanGesture
	if pg:
		if pg.ctrl_pressed:
			wb.draw_xform = zoom(wb.draw_xform, pg.position, exp(-pg.delta.y * 0.05))
			wb.redraw_all()
		else:
			wb.draw_xform = wb.draw_xform.translated(-pg.delta * 2.0)
			wb.redraw_all()
		wb.accept_event()
	var zg := event as InputEventMagnifyGesture
	if zg:
		wb.draw_xform = zoom(wb.draw_xform, zg.position, zg.factor)
		wb.redraw_all()
	return null


func pan(wb: Whiteboard, e: InputEventMouseButton, x: float, y: float) -> void:
	wb.draw_xform = wb.draw_xform.translated(0.5 * e.factor * Vector2(x, y))


func zoom(xform: Transform2D, screen_center: Vector2, amount: float) -> Transform2D:
	var center := screen_center
	if amount < 1 and xform.get_scale().length() / sqrt(2.0) < 0.2:
		return xform
	#if amount > 1 and xform.get_scale().length() / sqrt(2.0) < 0.1:
		#return xform
	return xform.translated_local(center).scaled_local(Vector2(amount, amount)).translated_local(-center)
