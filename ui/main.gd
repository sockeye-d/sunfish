@tool
extends Control

const SUNFISH = preload("uid://d0ovrms2e78nv")
const ANDROID = preload("res://android.png")

@onready var container: Control = %MarginContainer

@warning_ignore("unused_private_class_variable")
@export_tool_button("Scan plugins", "Search") var __ := func():
	PluginManager.scan_plugins()
	print(ThemeManager.themes)
	notify_property_list_changed()
@warning_ignore("unused_private_class_variable")
@export_tool_button("Reload theme", "Search") var ___ := func():
	ThemeManager.reload_theme()

@export var current_theme: String:
	set(value):
		current_theme = value
		update_theme.call_deferred()

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
	PluginManager.scan_plugins()
	ThemeManager.background_color_changed.connect(func(color: Color): self.color = color)
	current_theme = current_theme


func _process(delta: float) -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		container.offset_bottom = -DisplayServer.virtual_keyboard_get_height() / get_tree().root.content_scale_factor


func update_theme() -> void:
	print("hi")
	if current_theme in ThemeManager.themes:
		ThemeManager.set_theme_id(current_theme)
		propagate_notification(NOTIFICATION_THEME_CHANGED)
