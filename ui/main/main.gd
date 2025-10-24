@tool
extends ColorRect

@onready var container: Control = %MarginContainer
@onready var tool_scroll_container: ScrollContainer = %ToolScrollContainer
@onready var tool_scrollbar_separator: VSeparator = %ToolScrollbarSeparator

@warning_ignore("unused_private_class_variable")
@export_tool_button("Reload theme", "Search") var ___ := func():
	if not ThemeManager.active_theme:
		ThemeManager.set_theme_id("dev.fishies.sunfish.themes.CatppuccinMocha")
	else:
		ThemeManager.reload_theme()


func _validate_property(property: Dictionary) -> void:
	if property.name == "current_theme":
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(ThemeManager.themes.keys())


func _ready() -> void:
	Input.use_accumulated_input = false
	if OS.has_feature("mobile"):
		var safe_area := Rect2(DisplayServer.get_display_safe_area())
		var display_area := Vector2(DisplayServer.screen_get_size())
		container.offset_left = (safe_area.position.x) / get_tree().root.content_scale_factor
		container.offset_top = (safe_area.position.y) / get_tree().root.content_scale_factor
		container.offset_right = (display_area.x - safe_area.size.x - safe_area.position.x) / get_tree().root.content_scale_factor
		container.offset_bottom = (display_area.y - safe_area.size.y - safe_area.position.y) / get_tree().root.content_scale_factor
	ThemeManager.background_color_changed.connect(func(new_color: Color): color = new_color)
	if ThemeManager.active_theme:
		color = ThemeManager.active_theme.background_1
	tool_scroll_container.get_v_scroll_bar().visibility_changed.connect(func():
		tool_scrollbar_separator.visible = tool_scroll_container.get_v_scroll_bar().is_visible_in_tree()
	)
	if not Engine.is_editor_hint():
		get_tree().root.close_requested.connect(func():
			get_tree().root.propagate_notification(Util.NOTIFICATION_WINDOW_CLOSING)
			get_tree().quit()
		)


func _process(delta: float) -> void:
	Util.unused(delta)
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		container.offset_bottom = -DisplayServer.virtual_keyboard_get_height() / get_tree().root.content_scale_factor
