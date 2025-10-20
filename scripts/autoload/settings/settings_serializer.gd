extends Resource

@export_storage var property_values: Dictionary[StringName, Variant]


func generate_values() -> void:
	for key in Settings.config_data:
		property_values[key] = Settings.config_data[key].config


func get_safe(property: StringName) -> Variant:
	var sliced := property.split("/", true, 2)
	return property_values[sliced[0]][sliced[1]] if sliced[0] in property_values else null


func has(property: StringName) -> bool:
	var sliced := property.split("/", true, 2)
	return sliced[1] in property_values[sliced[0]] if sliced[0] in property_values else false
