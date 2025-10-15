extends WhiteboardTool


@export_range(1, 32, 1, "or_greater") var font_size: int = 16
@export var font_name: String = "serif"

var preview: TextPreviewElement
var last_found_element: TextElement

func _validate_property(property: Dictionary) -> void:
	if property.name == "font_name":
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(PackedStringArray(Inner.BUILTIN_FONT_MAP.keys()) + OS.get_system_fonts())


static func get_id() -> String: return "dev.fishies.sunfish.TextTool"


func receive_input(wb: Whiteboard, event: InputEvent) -> Display:
	Util.unused(wb)
	var display := Display.new()
	if event.is_action_pressed("ui_cancel"):
		preview = null
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if preview:
				var element := TextElement.new()
				element.text = preview.text
				element.font_name = font_name
				element.font_size = int(font_size / float(wb.draw_scale))
				element.position = mb.position
				element.color = wb.primary_color
				display.elements = [element]
				preview = null
			else:
				if last_found_element:
					var text = await DialogUtil.open_text_dialog(last_found_element.text, last_found_element.font)
					if text:
						last_found_element.text = text
						wb.redraw_canvas()
				else:
					var text = await DialogUtil.open_text_dialog("", Inner.create_font(font_name))
					if text:
						preview = TextPreviewElement.new()
						preview.text = text
						preview.font_name = font_name
						preview.position = mb.position
	var mm := event as InputEventMouseMotion
	if mm:
		if preview:
			preview.position = mm.position
		else:
			last_found_element = null
			for i in wb.elements.size():
				var el := wb.elements[wb.elements.size() - i - 1] as TextElement
				if el and el.get_bounding_box().has_point(mm.position):
					last_found_element = el
					wb.mouse_default_cursor_shape = Control.CURSOR_IBEAM
					break
			if not last_found_element and wb.mouse_default_cursor_shape == Control.CURSOR_IBEAM:
				wb.mouse_default_cursor_shape = Control.CURSOR_ARROW
	if preview:
		preview.color = wb.primary_color
		preview.font_size = int(font_size / float(wb.draw_scale))
		display.preview_elements = [preview]
	return display


class TextPreviewElement extends WhiteboardTool.PreviewElement:
	var text: String
	var position: Vector2
	var font_name: String:
		set(value):
			font = Inner.create_font(value)
	var font: Font
	var font_size: int
	var color: Color
	
	func draw(control: Control, wb: Whiteboard):
		var rect := Inner.font_get_rect(font, text, font_size)
		Util.unused(wb)
		control.draw_multiline_string(font, position - rect.get_center(), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, -1, color)


class TextElement extends WhiteboardTool.Element:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(TextElement)
	
	var text: String
	var position: Vector2
	var font_name: String:
		set(value):
			font = Inner.create_font(value)
			font_name = value
	var font: Font
	var font_size: int
	var color: Color
	
	static func get_id() -> String: return "dev.fishies.sunfish.TextElement"
	
	func draw(wb: Whiteboard):
		var rect := Inner.font_get_rect(font, text, font_size)
		wb.draw_multiline_string(font, position - rect.get_center(), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, -1, color)
	
	func get_bounding_box() -> Rect2:
		var rect := Inner.font_get_rect(font, text, font_size)
		rect.position += position - rect.get_center()
		return rect
	
	func serialize() -> Dictionary:
		return {
			"text": text,
			"position": position,
			"font_name": font_name,
			"font_size": font_size,
			"color": color,
		}
	
	static func deserialize(data: Dictionary) -> Element:
		var el := TextElement.new()
		el.text = data.text
		el.position = data.position
		el.font_name = data.font_name
		el.font_size = data.font_size
		el.color = data.color
		return el


class Inner:
	const BUILTIN_FONT_MAP: Dictionary[String, Font] = {
		"sans": ThemeManager.SANS,
		"sans-bold": ThemeManager.SANS_BOLD,
		"sans-italic": ThemeManager.SANS_ITALIC,
		"sans-bold-italic": ThemeManager.SANS_BOLD_ITALIC,
		"serif": ThemeManager.SERIF,
		"serif-bold": ThemeManager.SERIF_BOLD,
		"serif-italic": ThemeManager.SERIF_ITALIC,
		"serif-bold-italic": ThemeManager.SERIF_BOLD_ITALIC,
		"code": ThemeManager.CODE,
		"code-bold": ThemeManager.CODE_BOLD,
		"code-italic": ThemeManager.CODE_ITALIC,
		"code-bold-italic": ThemeManager.CODE_BOLD_ITALIC,
	}
	static var font_cache: Dictionary[String, Font]

	static func create_font(name: String) -> Font:
		if name in font_cache:
			return font_cache[name]
		if name in BUILTIN_FONT_MAP:
			var font := BUILTIN_FONT_MAP[name].duplicate()
			font.multichannel_signed_distance_field = true
			font_cache[name] = font
			return font
		var sys_font := SystemFont.new()
		sys_font.font_names = [name]
		sys_font.multichannel_signed_distance_field = true
		font_cache[name] = sys_font
		return sys_font
	
	static func font_get_rect(font: Font, text: String, font_size: int) -> Rect2:
		var string_size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		return Rect2(Vector2(0, font.get_descent(font_size) - font.get_height(font_size)), string_size)
