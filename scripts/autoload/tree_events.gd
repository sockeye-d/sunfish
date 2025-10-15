@tool
extends Node


func _ready() -> void:
	PluginManager.scan_plugins()
