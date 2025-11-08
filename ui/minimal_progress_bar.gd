@tool
class_name MinimalProgressBar extends Range


var background: StyleBox
var fill: StyleBox


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		background = get_theme_stylebox("background", "MinimalProgressBar")
		fill = get_theme_stylebox("fill", "MinimalProgressBar")
		queue_redraw()


func _value_changed(new_value: float) -> void:
	Util.unused(new_value)
	queue_redraw()


func _draw() -> void:
	var rid := get_canvas_item()
	if background:
		background.draw(rid, Rect2(Vector2.ZERO, size))
	if fill:
		fill.draw(rid, Rect2(0.0, 0.0, size.x * ratio, size.y))


func _get_minimum_size() -> Vector2:
	return Vector2(0.0, (background.content_margin_top + background.content_margin_bottom) if background else 0.0)
