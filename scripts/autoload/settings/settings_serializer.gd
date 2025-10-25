extends Resource

const SettingsSerializer = preload("settings_serializer.gd")

@export_storage var property_values: Dictionary[StringName, Variant]


var location: Configuration.Location


func generate_values() -> void:
	for key in Settings.config_data:
		var config: Configuration = Settings.config_data[key].config
		if config.get_location() == location:
			property_values[key] = config


func get_safe(property: StringName) -> Variant:
	var sliced := property.split("/", true, 2)
	return property_values[sliced[0]][sliced[1]] if sliced[0] in property_values else null


func has(property: StringName) -> bool:
	var sliced := property.split("/", true, 2)
	return sliced[1] in property_values[sliced[0]] if sliced[0] in property_values else false


static func merge(...resources: Array) -> Dictionary[StringName, Variant]:
	var merged: Dictionary[StringName, Variant]
	for res: SettingsSerializer in resources:
		merged.merge(res.property_values if res != null else {})
	return merged
