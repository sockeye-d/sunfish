class_name PluginExportPlatform extends EditorExportPlatformExtension


func _get_name() -> String:
	return "Plugin"


func _get_run_icon() -> Texture2D:
	return IconTexture2D.create("plugins", EditorInterface.get_editor_scale())


func _get_logo() -> Texture2D:
	return IconTexture2D.create("plugins", EditorInterface.get_editor_scale() * 2.0)


func _get_platform_features() -> PackedStringArray: return ["plugin"]


func _get_export_options() -> Array[Dictionary]:
	return [
		{
			"name": "include_core_plugins",
			"type": TYPE_BOOL,
		},
	]


func _get_binary_extensions(preset: EditorExportPreset) -> PackedStringArray: return ["zip"]


func _get_preset_features(preset: EditorExportPreset) -> PackedStringArray: return []


func _can_export(preset: EditorExportPreset, debug: bool) -> bool:
	return true


func _export_project(preset: EditorExportPreset, debug: bool, path: String, flags: int) -> Error:
	var zip := ZIPPacker.new()
	var open_err := zip.open(path)
	if open_err:
		return open_err
	export_project_files(preset, debug,
		func(file_path: String, file_data: PackedByteArray, file_index: int, file_count: int, encryption_include_filters: PackedStringArray, encryption_exclude_filters: PackedStringArray, encryption_key: PackedByteArray):
			if file_path.begins_with("res://icons"):
				return
			zip.start_file(file_path.trim_prefix("res:/"))
			zip.write_file(file_data)
			zip.close_file()
	)
	zip.close()
	return OK
