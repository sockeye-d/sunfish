class_name WindowAutoScaler extends Node


func _ready() -> void:
	await get_window().ready
	get_window().content_scale_factor = Settings["core/ui_scale"]
	get_window().oversampling_override = 0.0
	Settings.setting_changed("core/ui_scale").connect(func(new_value: float):
		get_window().content_scale_factor = new_value
		get_window().oversampling_override = 0.0
	)
