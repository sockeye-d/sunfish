@tool
@abstract class_name RadialPopup extends Control


const RADIUS = 125.0
const DEADZONE = 50.0
const THICKNESS = 64.0


signal item_selected(item: Item)


var items: Array[Item]
var visual := Visual.new()


var center_pos: Vector2
var mouse_pos: Vector2
var block_input := false


func _init() -> void:
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.radial_popup = self
	visual.animate_out_finished.connect(hide)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)
	hide()


@abstract func should_hide(event: InputEvent) -> bool


func _input(event: InputEvent) -> void:
	if not block_input:
		return
	if should_hide(event):
		block_input = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.animate_out()
		get_viewport().set_input_as_handled()
		var index := roundf(mouse_pos.angle() / TAU * items.size())
		var item = items[index]
		if mouse_pos.length() > DEADZONE and item.is_enabled():
			item_selected.emit(item)
	var mm := event as InputEventMouseMotion
	if mm:
		if not mm.relative.is_zero_approx():
			mouse_pos = mm.global_position - center_pos
			visual.queue_redraw()
	if block_input:
		get_viewport().set_input_as_handled()


func popup() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if get_parent() != get_tree().root:
		reparent(get_tree().root)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	show()
	visual.animate_in()
	block_input = true
	mouse_filter = Control.MOUSE_FILTER_STOP


@abstract class Item:
	@abstract func is_enabled() -> bool
	@abstract func draw(canvas: Control, rect: Rect2, highlight_factor: float, opacity: float) -> void
	@abstract func get_size() -> Vector2


class Visual extends Control:
	signal animate_out_finished
	var radial_popup: RadialPopup
	var tween: Tween
	var progress: float


	func animate_in() -> void:
		if tween and tween.is_valid():
			tween.kill()
		tween = create_tween()
		tween.tween_method(func(value: float):
			progress = value
			queue_redraw(),
		0.0, 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)


	func animate_out() -> void:
		if tween and tween.is_valid():
			tween.kill()
		tween = create_tween()
		tween.tween_method(func(value: float):
			progress = value
			queue_redraw(),
		progress, 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		tween.tween_callback(animate_out_finished.emit)


	func _draw() -> void:
		var index := 0
		var center := radial_popup.center_pos
		var mouse_angle := radial_popup.mouse_pos.angle()
		var angle_per_index := TAU / radial_popup.items.size()
		var outside_deadzone_fac := smoothstep(DEADZONE, DEADZONE + 30.0, radial_popup.mouse_pos.length())
		var circle_scale := lerpf(0.8, 1.0, progress)
		draw_circle(center, RADIUS * circle_scale, Color(ThemeManager.active_theme.background_1, progress), false, THICKNESS, true)
		draw_circle(center, DEADZONE, Color(ThemeManager.active_theme.overlay.lerp(ThemeManager.active_theme.overlay_press, outside_deadzone_fac), progress), false, 2.0 + 2.0 * outside_deadzone_fac, true)
		draw_arc(center, RADIUS * circle_scale, mouse_angle - angle_per_index * 0.5, mouse_angle + angle_per_index * 0.5, 16, Color(ThemeManager.active_theme.surface, outside_deadzone_fac * progress), THICKNESS * circle_scale, true)
		for item in radial_popup.items:
			var is_selected := not item.is_enabled()
			var angle := index * angle_per_index
			var angle_vec := Vector2.from_angle(angle)
			var draw_pos_center := center + angle_vec * Vector2(125, 125) * circle_scale
			var fac := pow(ease(1.0 - clampf(absf(angle_vec.angle_to(radial_popup.mouse_pos) / angle_per_index * 0.5 + 0.0) - 0.0, 0.0, 1.0), -2.0), 4.0) * outside_deadzone_fac
			var draw_scale := (0.5 if is_selected else lerpf(0.5, 1.0, fac)) * circle_scale
			var tex_rect := Rect2(draw_pos_center - item.get_size() * 0.5 * draw_scale * circle_scale, item.get_size() * draw_scale)
			item.draw(self, tex_rect, fac, progress)
			index += 1
