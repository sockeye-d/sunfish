extends WhiteboardTool

var is_dragging: bool = false
var drag_start_pos: Vector2


static func _static_init() -> void:
	WhiteboardManager.register_passive_tool(new())


static func get_id() -> StringName: return "dev.fishies.sunfish.PanTool"


static func is_visible() -> bool:
	return false


func receive_input(wb: Whiteboard, event: InputEvent) -> WhiteboardTool.Display:
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
						zoom(wb, mb.position, 1.0 * 1.1)
					else:
						pan(wb, mb, +00.0, +80.0)
					wb.accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					if mb.ctrl_pressed:
						zoom(wb, mb.position, 1.0 / 1.1)
					else:
						pan(wb, mb, +00.0, -80.0)
					wb.accept_event()
			MOUSE_BUTTON_WHEEL_LEFT:
				if mb.pressed:
					pan(wb, mb, +80.0, +00.0)
					wb.accept_event()
			MOUSE_BUTTON_WHEEL_RIGHT:
				if mb.pressed:
					pan(wb, mb, -80.0, +00.0)
					wb.accept_event()
	var mm := event as InputEventMouseMotion
	if mm:
		if is_dragging:
			if mm.ctrl_pressed:
				zoom(wb, drag_start_pos, exp(- mm.relative.y * 0.005 * wb.draw_scale))
			else:
				wb.draw_xform = wb.draw_xform.translated_local(mm.relative)
				wb.save()
			wb.accept_event()
	var pg := event as InputEventPanGesture
	if pg:
		if pg.ctrl_pressed:
			zoom(wb, pg.position, exp(-pg.delta.y * 0.05))
		else:
			wb.draw_xform = wb.draw_xform.translated(-pg.delta * 2.0)
			wb.save()
		wb.accept_event()
	var zg := event as InputEventMagnifyGesture
	if zg:
		zoom(wb, zg.position, zg.factor)
	return null


func pan(wb: Whiteboard, e: InputEventMouseButton, x: float, y: float) -> void:
	wb.draw_xform = wb.draw_xform.translated(0.5 * e.factor * Vector2(x, y))
	wb.save()


func zoom(wb: Whiteboard, screen_center: Vector2, amount: float) -> void:
	var center := screen_center
	if amount < 1 and wb.draw_scale < 0.2:
		return
	wb.draw_xform = wb.draw_xform.translated_local(center).scaled_local(Vector2(amount, amount)).translated_local(-center)
	wb.save()
