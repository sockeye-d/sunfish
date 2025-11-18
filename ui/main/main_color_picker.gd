@tool
extends NiceColorPicker


var color_popup := ColorPopup.new()


func _init() -> void:
	super()
	WhiteboardManager.register_radial_popup(color_popup, "shortcuts/show_color_pie")
	color_popup.item_selected.connect(func(item: ColorPopup.ColorItem): color = item.color)


func _ready() -> void:
	ThemeManager.active_theme_changed.connect(_reset_color_picker_colors)
	_reset_color_picker_colors()


func _reset_color_picker_colors() -> void:
	var colors: PackedColorArray = [
		ThemeManager.active_theme.text,
		ThemeManager.active_theme.subtext,
		ThemeManager.active_theme.accent_0,
		ThemeManager.active_theme.accent_1,
		ThemeManager.active_theme.error,
		ThemeManager.active_theme.warning,
		ThemeManager.active_theme.success,
	]
	set_swatches(colors)
	color_popup.items.clear()
	for swatch_color in colors:
		var item := ColorPopup.ColorItem.new()
		item.color = swatch_color
		color_popup.items.append(item)


class ColorPopup extends RadialPopup:
	class ColorItem extends Item:
		var color: Color
		var stylebox := StyleBoxFlat.new()
		func is_enabled() -> bool: return true
		func get_size() -> Vector2: return Vector2(50.0, 50.0)
		func draw(canvas: Control, rect: Rect2, highlight_factor: float) -> void:
			Util.unused(highlight_factor)
			stylebox.set_corner_radius_all(13)
			stylebox.bg_color = color
			#canvas.draw_rect(rect, color)
			stylebox.draw(canvas.get_canvas_item(), rect)

	func should_hide(event: InputEvent) -> bool:
		return event.is_match(Settings["shortcuts/show_color_pie"]) and not event.is_pressed()
