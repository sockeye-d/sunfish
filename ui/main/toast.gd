class_name Toast extends Container


var progress_bar := MinimalProgressBar.new()
var timer := Timer.new()
var stylebox: StyleBox
var panel: MarginContainer


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		stylebox = get_theme_stylebox("panel", "Toast")
		queue_sort()
		queue_redraw()
	if what == NOTIFICATION_PRE_SORT_CHILDREN:
		var rect := Rect2(stylebox.get_offset(), size - stylebox.get_minimum_size()) if stylebox else Rect2(Vector2.ZERO, size)
		for child in get_children(true):
			var control := child as Control
			if not control:
				continue
			fit_child_in_rect(control, rect)


func _get_minimum_size() -> Vector2:
	var max_size: Vector2
	for child in get_children(true):
		var control := child as Control
		if not control or not control.visible:
			continue
		max_size = max_size.max(control.get_combined_minimum_size())
	if stylebox:
		max_size += stylebox.get_minimum_size()
	return max_size


func _get_allowed_size_flags_horizontal() -> PackedInt32Array: return [
	SIZE_FILL,
	SIZE_SHRINK_BEGIN,
	SIZE_SHRINK_CENTER,
	SIZE_SHRINK_END,
]

func _get_allowed_size_flags_vertical() -> PackedInt32Array: return _get_allowed_size_flags_horizontal()


func _draw() -> void:
	var pivot := get_combined_pivot_offset()
	draw_set_transform_matrix(Transform2D.IDENTITY.translated(-pivot).scaled(panel.scale).translated(pivot))
	stylebox.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	timer.wait_time = Settings["core/toast_display_time"]
	timer.one_shot = true
	timer.timeout.connect(disappear)
	progress_bar.max_value = timer.wait_time
	progress_bar.step = 0.0
	add_child(timer)


func _ready() -> void:
	timer.start()


func _process(delta: float) -> void:
	Util.unused(delta)
	progress_bar.value = 0.0 if timer.is_stopped() else timer.time_left


func disappear() -> void:
	var tween := create_tween()
	pivot_offset_ratio = Vector2(0.5, 0.5)
	panel.pivot_offset_ratio = pivot_offset_ratio
	tween.tween_method(func(value: float):
		modulate.a = value
		queue_redraw()
	, 1.0, 0.0, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_callback(queue_free)


static func create(severity: ToastManager.Severity, message: String, additional_controls: Array[Control], custom_control: Control) -> Toast:
	var severity_color := _get_severity_color(severity)
	var toast := Toast.new()
	toast.panel = MarginContainer.new()
	toast.panel.add_theme_constant_override("margin_bottom", 0)
	toast.panel.add_theme_constant_override("margin_left", 0)
	toast.panel.add_theme_constant_override("margin_right", 0)
	toast.panel.add_theme_constant_override("margin_top", 0)
	var highlight := toast.panel.get_theme_stylebox("panel", "Toast").duplicate() as StyleBoxFlat
	highlight.set_border_width_all(1)
	highlight.expand_margin_left = highlight.content_margin_left
	highlight.expand_margin_right = highlight.content_margin_right
	highlight.expand_margin_top = highlight.content_margin_top
	highlight.expand_margin_bottom = highlight.content_margin_bottom
	highlight.bg_color = Color.TRANSPARENT
	highlight.border_color = severity_color
	var highlight_panel := PanelContainer.new()
	highlight_panel.add_theme_stylebox_override("panel", highlight)
	highlight_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	highlight_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	toast.panel.add_child(highlight_panel)
	var outer_container := VBoxContainer.new()
	var container := HBoxContainer.new()
	outer_container.add_child(container)
	toast.progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_container.add_child(toast.progress_bar)
	if custom_control == null:
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = message
		container.add_child(label)
		for control in additional_controls:
			container.add_child(control)
	else:
		container.add_child(custom_control)
		for control in additional_controls:
			container.add_child(control)

	toast.panel.add_child(outer_container)
	toast.add_child(toast.panel)
	return toast


static func _get_severity_color(severity: ToastManager.Severity) -> Color:
	match severity:
		ToastManager.Severity.INFO:
			return ThemeManager.active_theme.subtext
		ToastManager.Severity.SUCCESS:
			return ThemeManager.active_theme.success
		ToastManager.Severity.WARNING:
			return ThemeManager.active_theme.warning
		ToastManager.Severity.ERROR:
			return ThemeManager.active_theme.error
	return Color()
