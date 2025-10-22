@tool
extends Node


func _ready() -> void:
	PluginManager.scan_plugins([PluginManager.PLUGIN_PREFIX, "res://scripts/config"])
