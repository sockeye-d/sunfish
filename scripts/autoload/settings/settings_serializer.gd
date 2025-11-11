extends Resource

const _SettingsSerializer = preload("settings_serializer.gd")

enum SerializationMode {
	## Don't serialize this property.
	NONE,
	## Serialize it, but don't show it in the settings menu.
	SERIALIZE,
	## Serialize it and show it in the settings menu.
	SERIALIZE_EDITOR,
}

@export_storage var property_values: Dictionary[StringName, Dictionary]


var location: Configuration.Location


func generate_values() -> void:
	for key in Settings.config_data:
		var config: Configuration = Settings.config_data[key].config
		if config.get_location() == location:
			var data: Dictionary[StringName, Variant]
			for prop in config.get_property_list():
				if get_serialization_mode(prop) > SerializationMode.NONE:
					data[prop.name] = config.get(prop.name)
			property_values[key] = data


func has(property: StringName) -> bool:
	var sliced := property.split("/", true, 2)
	return sliced[1] in property_values[sliced[0]] if sliced[0] in property_values else false


static func merge(...resources: Array) -> Dictionary[StringName, Dictionary]:
	var merged: Dictionary[StringName, Dictionary]
	for res: _SettingsSerializer in resources:
		merged.merge(res.property_values if res != null else {})
	return merged


static func get_serialization_mode(property: Dictionary) -> SerializationMode:
	var usage: PropertyUsageFlags = property.usage
	if not usage & PROPERTY_USAGE_SCRIPT_VARIABLE or not usage & PROPERTY_USAGE_STORAGE:
		return SerializationMode.NONE
	if usage & PROPERTY_USAGE_EDITOR:
		return SerializationMode.SERIALIZE_EDITOR
	return SerializationMode.SERIALIZE
