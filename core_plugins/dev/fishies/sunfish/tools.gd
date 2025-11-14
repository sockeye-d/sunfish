extends Configuration


static func _static_init() -> void:
	PluginManager.register_configuration(new())


func get_id() -> StringName: return "dev.fishies.sunfish.tools"


@export var use_screen_space_brush_sizes: bool = true
