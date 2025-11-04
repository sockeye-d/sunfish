extends WhiteboardTool

const ScreenshotTool = preload("ScreenshotTool.gd")

enum SelectionSide {
	NONE,
	INNER,
	LEFT,
	TOP_LEFT,
	TOP,
	TOP_RIGHT,
	RIGHT,
	BOTTOM_RIGHT,
	BOTTOM,
	BOTTOM_LEFT,
}


static func get_id() -> StringName: return "dev.fishies.sunfish.ScreenshotTool"

var start_pos: Vector2
var preview := ScreenshotPreviewElement.new()
var dragging_side: SelectionSide
var whiteboard: Whiteboard


func activated(wb: Whiteboard) -> void:
	whiteboard = wb


func receive_input(wb: Whiteboard, event: InputEvent) -> Display:
	Util.unused(wb)
	var display := Display.new([], [], [preview])
	var handle_size := 8.0 / wb.draw_scale
	display.cursor_shape = Control.CURSOR_ARROW
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if preview.rect.grow(-handle_size).abs().has_point(mb.position):
					dragging_side = SelectionSide.INNER
				else:
					var closest_side: Array[SelectionSide]
					if get_closest_side(mb.position, preview.rect, closest_side) < handle_size:
						dragging_side = closest_side[0]
					else:
						preview.rect = Rect2(mb.position, Vector2())
						dragging_side = SelectionSide.NONE
				display.cursor_shape = get_cursor_shape(dragging_side, true)
			else:
				dragging_side = SelectionSide.NONE
				preview.rect = preview.rect.abs()
				if preview.rect.grow(-handle_size).abs().has_point(mb.position):
					display.cursor_shape = get_cursor_shape(SelectionSide.INNER, false)
	var mm := event as InputEventMouseMotion
	if mm:
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if dragging_side != SelectionSide.NONE:
				preview.rect = grow_rect(preview.rect, dragging_side, mm.relative)
			else:
				preview.rect.size = mm.position - preview.rect.position
		if dragging_side != SelectionSide.NONE:
			display.cursor_shape = get_cursor_shape(dragging_side, mm.button_mask & MOUSE_BUTTON_MASK_LEFT)
		else:
			if preview.rect.grow(-handle_size).abs().has_point(mm.position):
				display.cursor_shape = get_cursor_shape(SelectionSide.INNER, false)
			else:
				var closest_side: Array[SelectionSide]
				if get_closest_side(mm.position, preview.rect, closest_side) < handle_size:
					display.cursor_shape = get_cursor_shape(closest_side[0], mm.button_mask & MOUSE_BUTTON_MASK_LEFT)
	return display


static func get_side_rect_pos(rect: Rect2, side: SelectionSide) -> Vector2:
	match side:
		SelectionSide.LEFT:
			return Vector2(rect.position.x, rect.position.y + rect.size.y * 0.5)
		SelectionSide.TOP_LEFT:
			return Vector2(rect.position.x, rect.position.y)
		SelectionSide.TOP:
			return Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y)
		SelectionSide.TOP_RIGHT:
			return Vector2(rect.position.x + rect.size.x, rect.position.y)
		SelectionSide.RIGHT:
			return Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y * 0.5)
		SelectionSide.BOTTOM_RIGHT:
			return Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y)
		SelectionSide.BOTTOM:
			return Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y)
		SelectionSide.BOTTOM_LEFT:
			return Vector2(rect.position.x, rect.position.y + rect.size.y)
	return Vector2()


static func grow_rect(rect: Rect2, side: SelectionSide, delta: Vector2) -> Rect2:
	match side:
		SelectionSide.INNER:
			return Rect2(rect.position + delta, rect.size)
		SelectionSide.LEFT:
			return rect.grow_side(SIDE_LEFT, -delta.x)
		SelectionSide.TOP_LEFT:
			return rect.grow_side(SIDE_LEFT, -delta.x).grow_side(SIDE_TOP, -delta.y)
		SelectionSide.TOP:
			return rect.grow_side(SIDE_TOP, -delta.y)
		SelectionSide.TOP_RIGHT:
			return rect.grow_side(SIDE_RIGHT, delta.x).grow_side(SIDE_TOP, -delta.y)
		SelectionSide.RIGHT:
			return rect.grow_side(SIDE_RIGHT, delta.x)
		SelectionSide.BOTTOM_RIGHT:
			return rect.grow_side(SIDE_RIGHT, delta.x).grow_side(SIDE_BOTTOM, delta.y)
		SelectionSide.BOTTOM:
			return rect.grow_side(SIDE_BOTTOM, delta.y)
		SelectionSide.BOTTOM_LEFT:
			return rect.grow_side(SIDE_LEFT, -delta.x).grow_side(SIDE_BOTTOM, delta.y)
	return Rect2()


static func get_cursor_shape(side: SelectionSide, mb_pressed: bool) -> Control.CursorShape:
	match side:
		SelectionSide.INNER: return Control.CURSOR_CAN_DROP if mb_pressed else Control.CURSOR_DRAG
		SelectionSide.LEFT: return Control.CURSOR_HSIZE
		SelectionSide.TOP_LEFT: return Control.CURSOR_FDIAGSIZE
		SelectionSide.TOP: return Control.CURSOR_VSIZE
		SelectionSide.TOP_RIGHT: return Control.CURSOR_BDIAGSIZE
		SelectionSide.RIGHT: return Control.CURSOR_HSIZE
		SelectionSide.BOTTOM_RIGHT: return Control.CURSOR_FDIAGSIZE
		SelectionSide.BOTTOM: return Control.CURSOR_VSIZE
		SelectionSide.BOTTOM_LEFT: return Control.CURSOR_BDIAGSIZE
	return Control.CURSOR_ARROW


static func get_closest_side(mouse_pos: Vector2, rect: Rect2, out_side: Array[SelectionSide]) -> float:
	var closest_side: SelectionSide
	var closest_side_distance: float = INF
	for side in range(SelectionSide.LEFT, SelectionSide.size()):
		var side_pos := get_side_rect_pos(rect, side as SelectionSide)
		var distance := side_pos.distance_to(mouse_pos)
		if distance < closest_side_distance:
			closest_side_distance = distance
			closest_side = side as SelectionSide
	out_side.append(closest_side)
	return closest_side_distance


class ScreenshotPreviewElement extends StaticPreviewElement:
	var rect: Rect2
	func draw(wb: Whiteboard) -> void:
		const ARC_LENGTHS: PackedVector2Array = [
			Vector2(PI * 0.5, PI * 1.5),
			Vector2(PI * 0.5, TAU),
			Vector2(0.0, -PI),
			Vector2(-PI, PI * 0.5),
			Vector2(-PI * 0.5, PI * 0.5),
			Vector2(-PI * 0.5, PI),
			Vector2(0.0, PI),
			Vector2(0.0, PI * 1.5),
		]
		var xformed_rect := wb.draw_xform * rect
		wb.draw_rect(xformed_rect, ThemeManager.active_theme.accent_0, false, 2.0)
		for side in range(SelectionSide.LEFT, SelectionSide.size()):
			var arc_length := ARC_LENGTHS[side - 2]
			wb.draw_arc(
				ScreenshotTool.get_side_rect_pos(xformed_rect, side as SelectionSide),
				8.0,
				arc_length.x, arc_length.y, 16,
				ThemeManager.active_theme.accent_0, 1.0, true
			)
