@tool
class_name PluginManager


static var configurations: Dictionary[StringName, Configuration]


const PLUGIN_PREFIX := "res://plugins/"


static func scan_plugins(path := PLUGIN_PREFIX) -> void:
	for resource in ResourceLoader.list_directory(path):
		var full_path := path.path_join(resource)
		if resource.ends_with("/"):
			scan_plugins(full_path)
		else:
			load(full_path)


static func register_configuration(config: Configuration) -> void:
	configurations[config.get_id()] = config
