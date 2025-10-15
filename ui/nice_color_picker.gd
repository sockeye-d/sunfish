@tool
class_name NiceColorPicker extends VBoxContainer


signal color_changed(new_color: Color)


enum ClickedArea {
	NONE,
	HUE,
	SAT_VAL,
}

var hsv_color: Vector3:
	set(value):
		hsv_color = value
		(_color_wheel.material as ShaderMaterial).set_shader_parameter("hsv", hsv_color)
		color_changed.emit(color)
@export var color: Color:
	get: return Color.from_hsv(hsv_color.x, hsv_color.y, hsv_color.z)
	set(value): hsv_color = Vector3(value.h, value.s, value.v)

var _clicked_area := ClickedArea.NONE

var _color_wheel: ColorWheel
var _color_display: ColorDisplay
var _big_color_picker: ColorPicker
var _big_color_picker_panel: PopupPanel


func _init() -> void:
	_color_wheel = ColorWheel.new()
	_color_wheel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_color_wheel.gui_input.connect(_color_wheel_gui_input)
	add_child(_color_wheel)
	
	_big_color_picker_panel = PopupPanel.new()
	add_child(_big_color_picker_panel)
	
	_big_color_picker = ColorPicker.new()
	_big_color_picker.edit_alpha = false
	_big_color_picker.edit_intensity = false
	_big_color_picker.can_add_swatches = false
	_big_color_picker.presets_visible = false
	_big_color_picker.picker_shape = ColorPicker.SHAPE_NONE
	color_changed.connect(func(new_color: Color): _big_color_picker.color = new_color)
	_big_color_picker.color = color
	_big_color_picker.color_changed.connect(func(new_color: Color): color = new_color)
	_big_color_picker_panel.add_child(_big_color_picker)
	
	_color_display = ColorDisplay.new()
	_color_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	color_changed.connect(func(new_color: Color): _color_display.color = new_color)
	add_child(_color_display)
	
	#_color_display.toggle_mode = true
	_color_display.pressed.connect(func():
		_big_color_picker_panel.popup_on_parent(Rect2(_color_display.global_position + Vector2(0.0, _color_display.size.y), Vector2.ZERO))
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		fit_child_in_rect(_color_wheel, Rect2(Vector2.ZERO, Vector2(size.x, size.x)))


func _color_wheel_gui_input(e: InputEvent) -> void:
	var mb := e as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_clicked_area = _get_clicked_area(mb.position)
				_set_colors(mb)
			else:
				_clicked_area = ClickedArea.NONE
			_color_wheel.accept_event()
	var mm := e as InputEventMouseMotion
	if mm:
		if _clicked_area != ClickedArea.NONE:
			_set_colors(mm)
			_color_wheel.accept_event()


func _set_colors(mm: InputEventMouse) -> void:
	match _clicked_area:
		ClickedArea.HUE:
			hsv_color.x = _get_hue(mm.position)
		ClickedArea.SAT_VAL:
			var sv := _get_sat_val(mm.position)
			hsv_color.y = sv.x
			hsv_color.z = sv.y


func _get_clicked_area(click_pos: Vector2) -> ClickedArea:
	var uv := (click_pos / _color_wheel.size - Vector2.ONE * 0.5) * 2.0
	if uv.length() > 0.7:
		return ClickedArea.HUE
	return ClickedArea.SAT_VAL


func _get_hue(click_pos: Vector2) -> float:
	# this seems to work
	return (angle_difference(-(click_pos - _color_wheel.size * 0.5).angle(), PI) + PI) / TAU


func _get_sat_val(click_pos: Vector2) -> Vector2:
	var rot := (-hsv_color.x - 0.125) * TAU
	var uv := (click_pos / _color_wheel.size - Vector2.ONE * 0.5) * 2.0
	var square_size = Vector2(0.8, 0.8) * sqrt(0.5);
	var square_coords = (uv.rotated(rot) + square_size) / square_size * 0.5;
	return Vector2(square_coords.x, 1.0 - square_coords.y).clampf(0.0, 1.0)


class ColorWheel extends Control:
	const NICE_COLOR_PICKER_SHADER = preload("uid://bg1eurv6mma2w")
	
	func _init() -> void:
		material = ShaderMaterial.new()
		material.shader = NICE_COLOR_PICKER_SHADER
		mouse_filter = Control.MOUSE_FILTER_PASS
	
	
	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			update_minimum_size()
	
	
	func _draw() -> void:
		draw_rect(Rect2(-Vector2.ONE, size + Vector2.ONE), Color.RED)
	
	
	func _get_minimum_size() -> Vector2:
		return Vector2(150, size.x)


class ColorDisplay extends Button:
	var color: Color:
		set(value):
			color = value
			queue_redraw()
	
	func _ready() -> void:
		resized.connect(_set_minimum_size)
	
	func _draw() -> void:
		var sb := get_theme_stylebox("normal")
		var sb2 := StyleBoxFlat.new()
		sb2.set_corner_radius_all(4)
		sb2.bg_color = color
		var rect := Rect2(sb.get_offset(), size - sb.get_offset() - Vector2(sb.content_margin_right, sb.content_margin_bottom))
		sb2.draw(get_canvas_item(), rect)
		#draw_rect(, color)
	
	func _set_minimum_size() -> void:
		var sb := get_theme_stylebox("normal")
		var font_size := get_theme_font_size("font_size")
		custom_minimum_size = Vector2(0.0, sb.content_margin_top + sb.content_margin_bottom + font_size / 2.0)
