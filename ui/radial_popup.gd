@tool
@abstract class_name RadialPopup extends PopupPanel


const RADIUS = 125.0
const DEADZONE = 50.0
const THICKNESS = 64.0


signal item_selected(item: Item)


@export var whiteboard: Whiteboard

var items: Array[Item]
var visual := Visual.new()


var center_pos: Vector2
var mouse_pos: Vector2


func _init() -> void:
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.radial_popup = self
	add_child(visual)

	exclusive = true


func _ready() -> void:
	about_to_popup.connect(func():
		if get_theme_stylebox("panel") is not StyleBoxEmpty:
			add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	)


@abstract func should_hide(event: InputEvent) -> bool


func _input(event: InputEvent) -> void:
	if should_hide(event):
		var index := roundf(mouse_pos.angle() / TAU * items.size())
		var item = items[index]
		if mouse_pos.length() > DEADZONE and item.is_enabled():
			item_selected.emit(item)
		hide()
		set_input_as_handled()
	var mm := event as InputEventMouseMotion
	if mm:
		if not mm.relative.is_zero_approx():
			mouse_pos = mm.global_position - center_pos
			visual.queue_redraw()


@abstract class Item:
	@abstract func is_enabled() -> bool
	@abstract func draw(canvas: Control, rect: Rect2, highlight_factor: float) -> void
	@abstract func get_size() -> Vector2


class Visual extends Control:
	var radial_popup: RadialPopup


	func _draw() -> void:
		var index := 0
		var center := radial_popup.center_pos
		var mouse_angle := radial_popup.mouse_pos.angle()
		var angle_per_index := TAU / radial_popup.items.size()
		var outside_deadzone_fac := smoothstep(DEADZONE, DEADZONE + 30.0, radial_popup.mouse_pos.length())
		draw_circle(center, RADIUS, ThemeManager.active_theme.background_1, false, THICKNESS, true)
		draw_circle(center, DEADZONE, ThemeManager.active_theme.overlay.lerp(ThemeManager.active_theme.overlay_press, outside_deadzone_fac), false, 2.0 + 2.0 * outside_deadzone_fac, true)
		draw_arc(center, RADIUS, mouse_angle - angle_per_index * 0.5, mouse_angle + angle_per_index * 0.5, 16, Color(ThemeManager.active_theme.surface, outside_deadzone_fac), THICKNESS, true)
		for item in radial_popup.items:
			var is_selected := not item.is_enabled()
			var angle := index * angle_per_index
			var angle_vec := Vector2.from_angle(angle)
			var draw_pos_center := center + angle_vec * Vector2(125, 125)
			var fac := pow(ease(1.0 - clampf(absf(angle_vec.angle_to(radial_popup.mouse_pos) / angle_per_index * 0.5 + 0.0) - 0.0, 0.0, 1.0), -2.0), 4.0) * outside_deadzone_fac
			var draw_scale := 0.5 if is_selected else lerpf(0.5, 1.0, fac)
			var tex_rect := Rect2(draw_pos_center - item.get_size() * 0.5 * draw_scale, item.get_size() * draw_scale)
			item.draw(self, tex_rect, fac)
			index += 1
