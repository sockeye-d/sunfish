extends Resource


@export_storage var property_values: Dictionary[StringName, Variant]


func generate_values() -> void:
	for id in Settings.config_data:
		var config = Settings.config_data[id].config
		var values: Dictionary[String, Variant]
		for property in config.get_property_list():
			if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE or not property.usage & PROPERTY_USAGE_EDITOR:
				continue
			var value = config.get(property.name)
			if ClassDB.is_parent_class(property.class_name, "Resource") and value is Configuration:
				# don't serialize nested resources, they are flattened
				continue
			values[property.name] = value
			var property_id: String = config.get_id() + "/" + property.name
			property_values[property_id] = Settings.get_safe(property_id)[0]


func get_safe(property: StringName) -> Variant:
	return property_values[property] if property in property_values else null


func has(property_name: StringName) -> bool:
	return property_name in property_values
