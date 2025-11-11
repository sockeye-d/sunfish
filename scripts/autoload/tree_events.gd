@tool
extends Node


func _ready() -> void:
	if not Engine.is_editor_hint():
		PluginManager.load_plugins()
	var plugin_paths: PackedStringArray
	if not OS.has_feature("editor"):
		plugin_paths.append(PluginManager.PLUGIN_PREFIX)
	plugin_paths.append("res://scripts/config")
	plugin_paths.append(PluginManager.CORE_PLUGIN_PREFIX)
	PluginManager.scan_plugins(plugin_paths)


func _process(delta: float) -> void:
	Util.unused(delta)
	DeferredTask.process_tasks()


func restart() -> void:
	get_tree().root.propagate_notification(Util.NOTIFICATION_WINDOW_CLOSING)
	OS.create_instance(OS.get_cmdline_args())
	get_tree().quit()
