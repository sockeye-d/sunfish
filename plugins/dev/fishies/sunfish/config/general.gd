@tool
extends Configuration


@export var theme := "dev.fishies.sunfish.themes.CatppuccinMocha":
	set(value):
		theme = value
		update_theme.call_deferred()
@export var default_tool := "dev.fishies.sunfish.BrushTool"
@export var shortcut: InputEvent = null


static func _static_init() -> void:
	PluginManager.register_configuration(new())


func _init() -> void:
	ThemeManager.themes_changed.connect(notify_property_list_changed)


func update_theme() -> void:
	if theme in ThemeManager.themes:
		ThemeManager.set_theme_id(theme)


func _validate_property(property: Dictionary) -> void:
	if property.name == "theme":
		property.hint = Inspector.PROPERTY_HINT_EXT_PRETTY_RDNS_ENUM
		property.hint_string = ",".join(ThemeManager.themes.keys())
	if property.name == "default_tool":
		property.hint = Inspector.PROPERTY_HINT_EXT_PRETTY_RDNS_ENUM
		property.hint_string = ",".join(WhiteboardManager.tools.keys())


func get_id() -> String: return "dev.fishies.sunfish.config.general"
