@tool
class_name PluginManager


const PLUGIN_PREFIX := "res://plugins/"


static func scan_plugins(path := PLUGIN_PREFIX) -> void:
	for resource in ResourceLoader.list_directory(path):
		if resource.ends_with("/"):
			scan_plugins(path.path_join(resource))
		else:
			load(path.path_join(resource))
