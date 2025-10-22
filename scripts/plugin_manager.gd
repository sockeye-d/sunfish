@tool
class_name PluginManager

@warning_ignore_start("unused_signal")
signal pre_scan
signal post_scan
@warning_ignore_restore("unused_signal")


static var instance: PluginManager:
	get:
		if not instance:
			instance = new()
		return instance


static var configurations: Dictionary[StringName, Configuration]


const PLUGIN_PREFIX := "res://plugins/"


static func scan_plugins(paths: PackedStringArray = [PLUGIN_PREFIX]) -> void:
	instance.pre_scan.emit()
	for path in paths:
		_scan_plugins(path)
	instance.post_scan.emit()


static func _scan_plugins(path := PLUGIN_PREFIX) -> void:
	for resource in ResourceLoader.list_directory(path):
		var full_path := path.path_join(resource)
		if resource.ends_with("/"):
			_scan_plugins(full_path)
		else:
			load(full_path)


static func register_configuration(config: Configuration) -> void:
	configurations[config.get_id()] = config
