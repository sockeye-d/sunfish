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
var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		_update_image()
var _is_connected: bool = false


#static var _res_fs_script: Script:
	#get:
		#if not _res_fs_script:
			#_res_fs_script = GDScript.new()
			#_res_fs_script.source_code = """
#static func connect_resource_filesystem(to_func) -> void:
	#EditorInterface.get_resource_filesystem().resources_reimported.connect(to_func, CONNECT_DEFERRED)
#"""
			#_res_fs_script.reload()
		#return _res_fs_script


#func _init() -> void:
	#if Engine.is_editor_hint():
		#_res_fs_script.connect_resource_filesystem(func(resources: PackedStringArray): if _get_svg_path() in resources: _update_image())


func _update_image() -> void:
	var paths := _get_svg_path()
	var svg: String
	for path in paths:
		svg = _attempt_path(path)
		if svg:
			set_source(svg)
			base_scale = icon_scale * secondary_icon_scale
			color_map = { Color.WHITE: text_color * modulate }
			emit_changed()
			return


func _attempt_path(path: String) -> String:
	if OS.has_feature("editor"):
		return FileAccess.get_file_as_string(path)
	else:
		if ResourceLoader.exists(path, "DPITexture"):
			return (load(path) as DPITexture).get_source()
	return ""


func setup_signals() -> void:
	if not _is_connected:
		var scr := get_script() as Script
		if not scr.has_signal("change_text_color"):
			scr.add_user_signal("change_text_color", [{
				"name": "new_color",
				"type": TYPE_COLOR,
			}])
		scr.connect("change_text_color", func(new_color: Color):
			text_color = new_color
		)
		_is_connected = true 
		


#func svg_color(color: Color) -> 


func _get_svg_path() -> PackedStringArray:
	return ["res://assets/%s.svg" % icon, "res://plugins/%s.svg" % ReverseDNSUtil.id_to_path(icon)]
