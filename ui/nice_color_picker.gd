@tool
class_name NiceColorPicker extends Control


enum ClickedArea {
	NONE,
	HUE,
	SAT_VAL,
}


const NICE_COLOR_PICKER_SHADER = preload("uid://bg1eurv6mma2w")


var hsv_color: Vector3:
	set(value):
		hsv_color = value
		(material as ShaderMaterial).set_shader_parameter("hsv", color)
var color: Color:
	get: return Color(hsv_color.x, hsv_color.y, hsv_color.z)
	set(value): assert(false)
var last_clicked_area := ClickedArea.NONE


func _init() -> void:
	material = ShaderMaterial.new()
	material.shader = NICE_COLOR_PICKER_SHADER


func _draw() -> void:
	draw_rect(Rect2(-Vector2.ONE, size + Vector2.ONE), Color.BLACK)


func _gui_input(e: InputEvent) -> void:
	var mb := e as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				last_clicked_area = _get_clicked_area(mb.position)
				_set_colors(mb)
			else:
				last_clicked_area = ClickedArea.NONE
	var mm := e as InputEventMouseMotion
	if mm:
		_set_colors(mm)


func _get_minimum_size() -> Vector2:
	return Vector2(100, 100)


func _set_colors(mm: InputEventMouse) -> void:
	print(last_clicked_area)
	match last_clicked_area:
		ClickedArea.HUE:
			hsv_color.x = _get_hue(mm.position)
		ClickedArea.SAT_VAL:
			var sv := _get_sat_val(mm.position)
			hsv_color.y = sv.x
			hsv_color.z = sv.y


func _get_clicked_area(click_pos: Vector2) -> ClickedArea:
	var uv := (click_pos / size - Vector2.ONE * 0.5) * 2.0
	if uv.length() > 0.7:
		return ClickedArea.HUE
	return ClickedArea.SAT_VAL


func _get_hue(click_pos: Vector2) -> float:
	# this seems to work
	return (angle_difference(-(click_pos - size * 0.5).angle(), PI) + PI) / TAU


func _get_sat_val(click_pos: Vector2) -> Vector2:
	var rot := (-hsv_color.x - 0.125) * TAU
	var uv := (click_pos / size - Vector2.ONE * 0.5) * 2.0
	var square_size = Vector2(0.8, 0.8) * sqrt(0.5);
	var square_coords = (uv.rotated(rot) + square_size) / square_size * 0.5;
	return Vector2(square_coords.x, 1.0 - square_coords.y).clampf(0.0, 1.0)
