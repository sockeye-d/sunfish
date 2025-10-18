extends Resource

var obj

func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary]
	for id in obj.config_data:
		var config = obj.config_data[id].config
		var values: Dictionary[String, Variant]
		for property in config.get_property_list():
			if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				continue
			var value = config.get(property.name)
			if ClassDB.is_parent_class(property.class_name, "Resource") and value is Configuration:
				# don't serialize nested resources, they are flattened
				continue
			values[property.name] = value
			props.append({
				"name": config.get_id() + "/" + property.name,
				"type": property.type,
				"hint": PROPERTY_HINT_NONE,
				"usage": PROPERTY_USAGE_DEFAULT,
			})
	return props

func _get(property: StringName) -> Variant: return obj.get(property)


func save(path: String) -> void: ResourceSaver.save(self, path, ResourceSaver.FLAG_RELATIVE_PATHS)
