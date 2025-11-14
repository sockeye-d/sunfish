extends Configuration


#static func _static_init() -> void:
	#PluginManager.register_configuration(new())


func get_id() -> StringName: return "display"


@export_custom(
	Inspector.PROPERTY_HINT_EXT_RANGE_ENUM,
	'{ "range": [0.25, 3.0], "step": 0.25, "percentage": true }'
) var ui_scale := 3.0 if OS.has_feature("mobile") else 1.0:
	set(value):
		ui_scale = value
		ThemeManager.ui_scale = ui_scale


@export_range(0.0, 480.0, 1.0, "or_greater") var max_framerate := _get_highest_framerate():
	set(value):
		max_framerate = value
		Engine.max_fps = int(max_framerate)


func _get_highest_framerate() -> float:
	var highest_framerate := -1.0
	for screen in DisplayServer.get_screen_count():
		highest_framerate = maxf(highest_framerate, DisplayServer.screen_get_refresh_rate(screen))
	if highest_framerate < 0.0:
		highest_framerate = 60.0
	return highest_framerate
