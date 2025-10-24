@tool
extends Node


func _ready() -> void:
	PluginManager.load_plugins()
	PluginManager.scan_plugins([PluginManager.PLUGIN_PREFIX, "res://scripts/config"])


func restart() -> void:
	get_tree().root.propagate_notification(Util.NOTIFICATION_WINDOW_CLOSING)
	OS.create_instance(OS.get_cmdline_args())
	get_tree().quit()
