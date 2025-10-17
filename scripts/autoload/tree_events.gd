@tool
extends Node


func _ready() -> void:
	PluginManager.scan_plugins()
	PluginManager.scan_plugins("res://scripts/config")
