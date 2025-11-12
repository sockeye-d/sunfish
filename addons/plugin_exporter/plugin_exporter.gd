@tool
extends EditorPlugin


var plugin_export_plugin := PluginExportPlugin.new()
var plugin_export_platform := PluginExportPlatform.new()
var svg_import_plugin := preload("svg_import_plugin.gd").new()


func _enter_tree() -> void:
	add_export_plugin(plugin_export_plugin)
	add_export_platform(plugin_export_platform)
	add_import_plugin(svg_import_plugin)


func _exit_tree() -> void:
	remove_export_plugin(plugin_export_plugin)
	remove_export_platform(plugin_export_platform)
	remove_import_plugin(svg_import_plugin)
