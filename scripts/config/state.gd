extends Configuration


static func _static_init() -> void:
	PluginManager.register_configuration(new())


func get_id() -> StringName: return "state"


func get_location() -> Location: return Location.LOCAL


@export_storage var last_opened_filepath: String
## Dictionary[StringName (tool ID), Dictionary[StringName (property ID), Variant]]
@export_storage var tool_properties: Dictionary[StringName, Dictionary]
