extends Configuration


static func _static_init() -> void:
	PluginManager.register_configuration(new())


func get_id() -> String: return "state"


@export_storage var last_opened_filepath: String
