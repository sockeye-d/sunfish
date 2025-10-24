extends Configuration


static func _static_init() -> void:
	PluginManager.register_configuration(new())


func get_id() -> StringName: return "shortcuts.tools"


@export_storage var shortcut_values: Dictionary[StringName, InputEvent]


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary]
	var assign_shortcuts := shortcut_values.is_empty()
	for tool in WhiteboardManager.tools:
		props.append({
			"name": tool,
			"type": TYPE_OBJECT,
			"class_name": "InputEvent",
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "InputEvent",
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
		})
		if assign_shortcuts:
			shortcut_values[tool] = WhiteboardManager.tools[tool].get_shortcut()
	return props


func _property_get_revert(property: StringName) -> Variant:
	if property in WhiteboardManager.tools:
		return WhiteboardManager.tools[property].get_shortcut()
	else:
		return null


func _get(property: StringName) -> Variant: return shortcut_values.get(property, null)


func _set(property: StringName, value: Variant) -> bool:
	shortcut_values[property] = value
	return true
