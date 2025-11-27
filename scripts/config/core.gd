extends Configuration


const Display = preload("display.gd")


static func _static_init() -> void:
	PluginManager.register_configuration(new())


func get_id() -> StringName: return "core"


@export var theme := "dev.fishies.sunfish.themes.CatppuccinMocha":
	set(value):
		theme = value
		update_theme()
@export var default_tool := "dev.fishies.sunfish.BrushTool"

@export_range(0.1, 10.0, 0.01, "or_greater") var toast_display_time: float = 5.0

## Whether or not to spread computation across multiple frames. This can increase responsiveness at
## the cost of a "pop-in" effect, especially when changing themes or GUI scales.
@export var use_deferred_tasks: bool = false:
	set(value):
		use_deferred_tasks = value
		DeferredTask.use_deferred_tasks = use_deferred_tasks

@export var show_debug_menu: bool = false

@export var use_text_save_format: bool = false

@export_storage var tool_layout: Array[StringName]


@export var display := Display.new()


func _init() -> void:
	ThemeManager.themes_changed.connect(notify_property_list_changed)


func update_theme() -> void:
	if theme in ThemeManager.themes:
		ThemeManager.set_theme_id(theme)


func _property_get_revert(property: StringName) -> Variant:
	if property == &"tool_layout":
		var tools: Array[StringName]
		tools.assign(WhiteboardManager.tools.keys())
		return tools
	return null


func _validate_property(property: Dictionary) -> void:
	if property.name == "theme":
		property.hint = Inspector.PROPERTY_HINT_EXT_PRETTY_RDNS_ENUM
		property.hint_string = ",".join(ThemeManager.themes.keys())
	if property.name == "default_tool":
		property.hint = Inspector.PROPERTY_HINT_EXT_PRETTY_RDNS_ENUM
		property.hint_string = ",".join(WhiteboardManager.tools.keys())
