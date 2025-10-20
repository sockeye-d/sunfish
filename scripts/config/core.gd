extends Configuration


static func _static_init() -> void:
	PluginManager.register_configuration(new())


func get_id() -> String: return "core"


@export var show_debug_menu: bool = false
