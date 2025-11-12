@tool
class_name SVGResourceFormatLoader extends ResourceFormatLoader


func _get_dependencies(path: String, add_types: bool) -> PackedStringArray:
	return ["uid://bpi1kql7witnv::Script"]


func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var svg := SVG.new()
	svg.source = file.get_as_text()
	svg.resource_path = original_path
	return svg


func _recognize_path(path: String, type: StringName) -> bool:
	return path.ends_with(".svg") and type == "SVG"
