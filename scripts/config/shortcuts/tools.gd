extends Configuration


static func _static_init() -> void:
	PluginManager.register_configuration(new())


func get_id() -> StringName: return "shortcuts.tools"


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary]
	for tool in WhiteboardManager.tools:
		props.append({
			"name": tool,
			"type": TYPE_OBJECT,
			"class_name": "InputEvent",
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "InputEvent",
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
		})
	return props
