@tool
class_name IconTexture2D extends ImageTexture


@export var icon: String:
	get: return icon
	set(value):
		icon = value
		_update_image()
@export_range(0.5, 3.0, 0.0001, "or_greater", "or_less") var icon_scale: float = 1.0:
	get: return icon_scale
	set(value):
		icon_scale = value
		_update_image()


func _update_image() -> void:
	var svg := FileAccess.get_file_as_string("res://assets/%s.svg" % icon)
	if svg:
		var img := Image.new()
		img.load_svg_from_string(svg, icon_scale)
		set_block_signals(true)
		set_image(img)
		set_block_signals(false)
		emit_changed()
	else:
		var img := Image.create_empty(int(16 * icon_scale), int(16 * icon_scale), false, Image.FORMAT_RGBA8)
		@warning_ignore("integer_division")
		var half_w := img.get_width() / 2
		@warning_ignore("integer_division")
		var half_h := img.get_height() / 2
		img.fill_rect(Rect2i(     0,      0, half_w, half_h), Color(1, 0, 1))
		img.fill_rect(Rect2i(half_w,      0, half_w, half_h), Color(0, 0, 0))
		img.fill_rect(Rect2i(half_w, half_h, half_w, half_h), Color(1, 0, 1))
		img.fill_rect(Rect2i(0,      half_h, half_w, half_h), Color(0, 0, 0))
		set_block_signals(true)
		set_image(img)
		set_block_signals(false)
		emit_changed()
