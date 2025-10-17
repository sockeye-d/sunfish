@tool
extends Configuration


@export var theme: String = "dev.fishies.sunfish.themes.CatppuccinMocha":
	set(value):
		theme = value
		update_theme.call_deferred()
@export var default_tool: String = "dev.fishies.sunfish.BrushTool"


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


class Subconfiguration extends Configuration:
	@export var hi: String = "hi"
	func get_id() -> String: return "dev.fishies.sunfish.config.general.subgeneral"
