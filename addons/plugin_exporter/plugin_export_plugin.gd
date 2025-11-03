class_name PluginExportPlugin extends EditorExportPlugin


var should_apply_plugin: bool
var include_core_plugins: bool


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	should_apply_plugin = "plugin" in features


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if not should_apply_plugin:
		return
	if not path.begins_with("res://plugins"):
		skip()
