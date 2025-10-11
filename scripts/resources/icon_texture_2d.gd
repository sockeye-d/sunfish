@tool
class_name IconTexture2D extends DPITexture


@export var icon: String:
	get: return icon
	set(value):
		icon = value
		_update_image()
@export_range(0.5, 3.0, 0.0001, "or_greater", "or_less") var icon_scale: float = 1.0:
	get: return icon_scale
	set(value):
		icon_scale = value
		_update_image()
@export var modulate: Color = Color.WHITE:
	set(value):
		modulate = value
		_update_image()
var text_color: Color = Color.RED:
	set(value):
		text_color = value
		_update_image()


static var _res_fs_script: Script:
	get:
		if not _res_fs_script:
			_res_fs_script = GDScript.new()
			_res_fs_script.source_code = """
static func connect_resource_filesystem(to_func) -> void:
	EditorInterface.get_resource_filesystem().resources_reimported.connect(to_func, CONNECT_DEFERRED)
"""
			_res_fs_script.reload()
		return _res_fs_script


func _init() -> void:
	if Engine.is_editor_hint():
		_res_fs_script.connect_resource_filesystem(func(resources: PackedStringArray): if _get_svg_path() in resources: _update_image())
	SignalBus.instance.change_text_color.connect(func(new_color: Color): text_color = new_color)


func _update_image() -> void:
	var svg := FileAccess.get_file_as_string(_get_svg_path()) if OS.has_feature("editor") else (load(_get_svg_path()) as DPITexture).get_source()
	if svg:
		base_scale = icon_scale
		color_map[Color.WHITE] = text_color * modulate
		set_source(svg)


#func svg_color(color: Color) -> 


func _get_svg_path() -> String: return "res://assets/%s.svg" % icon


class SignalBus:
	signal change_text_color(new_color: Color)
	static var instance: SignalBus:
		get:
			if not instance:
				instance = SignalBus.new()
			return instance
