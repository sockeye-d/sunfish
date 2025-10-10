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


static var _res_fs_script: Script:
	get:
		if not _res_fs_script:
			var script := GDScript.new()
			script.source_code = """
static func connect_resource_filesystem(to_func) -> void:
	EditorInterface.get_resource_filesystem().resources_reimported.connect(to_func, CONNECT_DEFERRED)
"""
			script.reload()
			_res_fs_script = script
		return _res_fs_script


func _init() -> void:
	if Engine.is_editor_hint():
		_res_fs_script.connect_resource_filesystem(func(resources: PackedStringArray): if _get_svg_path() in resources: _update_image())


func _update_image() -> void:
	var svg := FileAccess.get_file_as_string(_get_svg_path()) if OS.has_feature("editor") else (load(_get_svg_path()) as DPITexture).get_source()
	if svg:
		base_scale = icon_scale
		set_source(svg)
		#var img := Image.new()
		#img.load_svg_from_string(svg, icon_scale)
		#set_block_signals(true)
		#set_image(img)
		#set_block_signals(false)
		#emit_changed()
	#else:
		#var img := Image.create_empty(int(16 * icon_scale), int(16 * icon_scale), false, Image.FORMAT_RGBA8)
		#@warning_ignore("integer_division")
		#var half_w := img.get_width() / 2
		#@warning_ignore("integer_division")
		#var half_h := img.get_height() / 2
		#img.fill_rect(Rect2i(     0,      0, half_w, half_h), Color(1, 0, 1))
		#img.fill_rect(Rect2i(half_w,      0, half_w, half_h), Color(0, 0, 0))
		#img.fill_rect(Rect2i(half_w, half_h, half_w, half_h), Color(1, 0, 1))
		#img.fill_rect(Rect2i(0,      half_h, half_w, half_h), Color(0, 0, 0))
		#set_block_signals(true)
		#set_image(img)
		#set_block_signals(false)
		#emit_changed()


func _get_svg_path() -> String: return "res://assets/%s.svg" % icon
