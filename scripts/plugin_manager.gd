@tool
class_name PluginManager

@warning_ignore_start("unused_signal")
signal pre_scan
signal post_scan

signal plugin_added(plugin: PluginData)
signal plugin_removed(plugin: PluginData)
@warning_ignore_restore("unused_signal")


static var instance: PluginManager:
	get:
		if not instance:
			instance = new()
		return instance


static var configurations: Dictionary[StringName, Configuration]
static var plugins: Array[PluginData]
static var _plugins_on_load: Array[PluginData]
static var plugin_meta_path := OS.get_config_dir().path_join("sunfish/plugins.json")
static var plugin_path := OS.get_config_dir().path_join("sunfish/plugins/")


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


static func add_plugin(source_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(plugin_path)
	DirAccess.copy_absolute(source_path, plugin_path.path_join(source_path.get_file()))
	var plugin := PluginData.new(source_path.get_file(), true)
	plugins.append(plugin)
	instance.plugin_added.emit(plugin)
	serialize_plugins()


static func remove_plugin(plugin: PluginData) -> void:
	plugins.remove_at(plugins.find(plugin))
	DirAccess.remove_absolute(plugin.get_absolute_path())
	instance.plugin_removed.emit(plugin)
	serialize_plugins()


static func load_plugins() -> void:
	deserialize_plugins()
	for plugin in plugins:
		if not plugin.enabled:
			continue
		var succeeded := ProjectSettings.load_resource_pack(plugin.get_absolute_path(), false)
		if not succeeded:
			printerr("Plugin %s failed to load" % plugin)
			plugin.enabled = false
	for plugin in plugins:
		_plugins_on_load.append(PluginData.new(plugin.name, plugin.enabled))


static func deserialize_plugins() -> void:
	var json = JSON.parse_string(FileAccess.get_file_as_string(plugin_meta_path))
	if json == null:
		return
	for plugin in json:
		plugins.append(PluginData.new(plugin.name, plugin.enabled))


static func serialize_plugins() -> void:
	var data: Array[Dictionary]
	for plugin in plugins:
		data.append({
			"name": plugin.name,
			"enabled": plugin.enabled,
		})
	var file := FileAccess.open(plugin_meta_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  "))


static func are_plugins_changed() -> bool:
	if _plugins_on_load.size() != plugins.size():
		return true
	for i in plugins.size():
		if _plugins_on_load[i].enabled != plugins[i].enabled or _plugins_on_load[i].name != plugins[i].name:
			return true
	return false


class PluginData:
	var name: StringName
	var enabled: bool:
		set(value):
			enabled = value
			PluginManager.serialize_plugins.call_deferred()


	func _init(_name: StringName, _enabled: bool) -> void:
		name = _name
		enabled = _enabled


	func get_absolute_path() -> String:
		return PluginManager.plugin_path.path_join(name)
