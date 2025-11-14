@tool
class_name IconTexture2D extends DPITexture


@export var icon: String:
	get: return icon
	set(value):
		setup_signals()
		icon = value
		_update_image()
@export_range(0.5, 3.0, 0.0001, "or_greater", "or_less") var icon_scale: float = 1.0:
	get: return icon_scale
	set(value):
		icon_scale = value
		_update_image()
var secondary_icon_scale: float = 1.0:
	get: return secondary_icon_scale
	set(value):
		secondary_icon_scale = value
		_update_image()
@export var modulate: Color = Color.WHITE:
	set(value):
		modulate = value
		_update_image()
static var global_color_map: Dictionary[Color, Color]


var last_task_handle := DeferredTask.INVALID_TASK


func _init() -> void:
	SignalBus.instance.update.connect(_update_image)


func _update_image() -> void:
	var paths := _get_svg_path()
	var svg: String
	for path in paths:
		svg = _attempt_path(path)
		if svg.is_empty():
			continue
		DeferredTask.cancel(last_task_handle)
		last_task_handle = DeferredTask.create(func():
			set_source(svg)
			base_scale = icon_scale * secondary_icon_scale
			color_map = global_color_map
		)
		return


func _attempt_path(path: String) -> String:
	if OS.has_feature("editor"):
		return FileAccess.get_file_as_string(path)
	else:
		var res := load(path) as SVG
		if res: return res.source
	return ""


func setup_signals() -> void:
	if not SignalBus.instance.update.is_connected(_update_image):
		SignalBus.instance.update.connect(_update_image)


func _get_svg_path() -> PackedStringArray:
	var icon_path := ReverseDNSUtil.id_to_path(icon) + ".svg"
	return [
		"res://assets/%s.svg" % icon,
		PluginManager.PLUGIN_PREFIX + icon_path,
		PluginManager.CORE_PLUGIN_PREFIX + icon_path,
	]


static func create(icon_name: String, scale: float = 1.0) -> IconTexture2D:
	var i := new()
	i.icon = icon_name
	i.icon_scale = scale
	return i


class SignalBus:
	signal update
	static var instance: SignalBus:
		get:
			if not instance:
				instance = SignalBus.new()
			return instance
