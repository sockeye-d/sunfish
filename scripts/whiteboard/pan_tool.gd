extends WhiteboardTool


func receive_input(wb: Whiteboard, event: InputEvent) -> WhiteboardTool.Display:
	var mb := event as InputEventMouseButton
	if mb:
		match mb.button_index:
			MOUSE_BUTTON_MIDDLE:
				wb.mouse_default_cursor_shape = Control.CURSOR_DRAG if mb.pressed else Control.CURSOR_ARROW
			MOUSE_BUTTON_WHEEL_UP:
				if mb.ctrl_pressed:
					wb.draw_xform = zoom(wb.draw_xform, mb.position, 1.0 * 1.1)
					wb.redraw_all()
				else:
					pan(wb, mb, +00.0, +20.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.ctrl_pressed:
					wb.draw_xform = zoom(wb.draw_xform, mb.position, 1.0 / 1.1)
					wb.redraw_all()
				else:
					pan(wb, mb, +00.0, -20.0)
			MOUSE_BUTTON_WHEEL_LEFT:
				pan(wb, mb, +20.0, +00.0)
			MOUSE_BUTTON_WHEEL_RIGHT:
				pan(wb, mb, -20.0, +00.0)
	var mm := event as InputEventMouseMotion
	if mm:
		if mm.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			wb.draw_xform = wb.draw_xform.translated(mm.relative * wb.draw_scale)
			wb.redraw_all()
	return null


func pan(wb: Whiteboard, e: InputEventMouseButton, x: float, y: float) -> void:
	wb.draw_xform = wb.draw_xform.translated(0.5 * e.factor * Vector2(x, y))
	wb.redraw_all()


func zoom(xform: Transform2D, screen_center: Vector2, amount: float) -> Transform2D:
	var center = screen_center
	return xform.translated_local(center).scaled_local(Vector2(amount, amount)).translated_local(-center)
