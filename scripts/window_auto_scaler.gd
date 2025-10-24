class_name WindowAutoScaler extends Node


func _ready() -> void:
	await get_tree().root.ready
	get_window().content_scale_factor = Settings["core/ui_scale"]
	Settings.setting_changed("core/ui_scale").connect(func(new_value): get_window().content_scale_factor = new_value)
