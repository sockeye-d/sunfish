extends Node


func _ready() -> void:
	RenderingServer.global_shader_parameter_set("ui_scale", get_tree().root.content_scale_factor)
