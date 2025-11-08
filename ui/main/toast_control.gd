@tool
extends Control


@export var toast_severity: ToastManager.Severity
@export_tool_button("Create toast", "Bake") var create_toast := func():
	ToastManager.push_toast(toast_severity, "Hi!")
@export_tool_button("Clear toasts", "Bake") var clear_toasts := func():
	for child in get_children():
		if child.owner == null:
			child.queue_free()
var tween: Tween


func _ready() -> void:
	ToastManager.toasts_active = true
	ToastManager.toast_pushed.connect(_on_toast_pushed)


func _on_toast_pushed(severity: ToastManager.Severity, message: String, custom_control: Control) -> void:
	var toast := _create_toast(severity, message, custom_control)
	add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	toast.anchor_left = 0.3
	toast.anchor_right = 0.7
	var height := -toast.offset_top
	toast.offset_top = 0.0
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(toast, "offset_top", 0.0, 0.5)


func _get_severity_color(severity: ToastManager.Severity) -> Color:
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


func _create_toast(severity: ToastManager.Severity, message: String, custom_control: Control) -> Control:
	var severity_color := _get_severity_color(severity)
	var panel := PanelContainer.new()
	var highlight := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	highlight.set_border_width_all(2)
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
	panel.add_child(highlight_panel)
	var container := HBoxContainer.new()
	panel.resized.connect(func():
		panel.queue_redraw()
	)
	if custom_control == null:
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = message
		container.add_child(label)
	else:
		container.add_child(custom_control)

	panel.add_child(container)
	return panel
