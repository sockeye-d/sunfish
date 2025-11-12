@tool
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "dev.fishies.svg_import_plugin"

func _get_visible_name() -> String:
	return "SVG"

func _get_recognized_extensions() -> PackedStringArray:
	return ["svg"]

func _get_save_extension() -> String:
	return "res"

func _get_resource_type() -> String:
	return "SVG"

func _get_preset_count() -> int:
	return 1

func _get_preset_name(preset_index: int) -> String:
	return "Default"

func _get_import_options(path, preset_index) -> Array[Dictionary]:
	return []

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FAILED
	var svg := SVG.new()
	svg.source = file.get_as_text()
	var filename := save_path + "." + _get_save_extension()
	return ResourceSaver.save(svg, filename)
