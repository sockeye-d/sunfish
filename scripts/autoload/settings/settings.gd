## The autoloaded settings window, used to set, get, and manage any serializable property. Used in
## combination with [Configuration]s.
@tool extends Window

## Emitted when the setting specified by [param property] is changed to the value of [new_value].
## Also emitted when using [method Object.set].
signal any_setting_changed(property: StringName, new_value)

signal _shortcut_search_changed(text_filter: String, event_filter: InputEvent)

const _RESET_ICON = preload("uid://dmah5fp6rgtqt")
const _SettingsSerializer = preload("uid://cphoy3o8egue5")

## The path to the config file.
var config_path := OS.get_config_dir().path_join("sunfish/settings.tres")
## The path to the state file.
var local_path := OS.get_user_data_dir().path_join("state.tres")


@onready var _tree: Tree = %Tree
@onready var _settings_container: Container = %SettingsContainer
@onready var _shortcut_container: GridContainer = %ShortcutContainer
@onready var _shortcut_search_text: LineEdit = %ShortcutSearchText
@onready var _shortcut_search_event: EventInput = %ShortcutSearchEvent
@onready var _tab_container: TabContainer = %TabContainer

## Map of [StringName] IDs to the ["scripts/autoload/settings/settings.gd".ConfigurationData].
var config_data: Dictionary[StringName, ConfigurationData]
var _signals: Dictionary[StringName, Signal]


func _ready() -> void:
	close_requested.connect(hide)
	if OS.has_feature("mobile"):
		size = Vector2i(500, 275)
		position = get_tree().root.size / 2.0 / get_tree().root.content_scale_factor - size / 2.0
	var deserialized_settings := _SettingsSerializer.merge(_load(config_path), _load(local_path))
	_reload_settings(deserialized_settings)
	_shortcut_search_text.text_changed.connect(_emit_shortcut_search_changed)
	_shortcut_search_event.event_changed.connect(_emit_shortcut_search_changed)
	_settings_container.add_child(config_data["core"].control)


func _load(path: String) -> _SettingsSerializer:
	if not FileAccess.file_exists(path):
		return null
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)


func _emit_shortcut_search_changed(_v) -> void:
	_shortcut_search_changed.emit(_shortcut_search_text.text, _shortcut_search_event.last_event)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()


func _reload_settings(serialized_data: Dictionary[StringName, Dictionary]) -> void:
	const EMPTY_DATA: Dictionary[StringName, Variant] = {}
	for key in config_data:
		var data := config_data[key]
		data.control.queue_free()
	for child in _shortcut_container.get_children():
		child.queue_free()
	config_data.clear()
	_tree.clear()
	var root := _tree.create_item()
	for config in PluginManager.configurations:
		_create_settings_for(root, PluginManager.configurations[config], serialized_data.get(config, EMPTY_DATA))


func _create_settings_for(parent: TreeItem, config: Configuration, serialized_data: Dictionary[StringName, Variant]) -> void:
	var id := config.get_id()
	var tree_item := parent.create_child()
	var grid_container := GridContainer.new()
	grid_container.columns = 2
	grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_item.set_text(0, ReverseDNSUtil.pretty_print(id))
	tree_item.set_metadata(0, id)
	tree_item.set_tooltip_text(0, id)
	var has_tree_worthy_properties := false
	var has_created_shortcut_header := false
	var data := ConfigurationData.new()
	data.config = config
	data.control = grid_container
	config_data[id] = data
	for property in config.get_property_list():
		var property_usage: PropertyUsageFlags = property.usage
		if _SettingsSerializer.get_serialization_mode(property) <= _SettingsSerializer.SerializationMode.NONE:
			continue
		var property_name: StringName = property.name
		var property_class: StringName = property.class_name

		# Check for a custom property revert value, and if it doesn't exist, check for an initial
		# value (like from a setter)
		var value = config.property_get_revert(property_name)
		if value == null: value = config.get(property_name)

		if value is Configuration and property_usage & PROPERTY_USAGE_EDITOR:
			_create_settings_for(tree_item, value, serialized_data)
			continue

		var property_key := StringName(id + "/" + property_name)
		var is_shortcut := ClassDB.is_parent_class(property_class, "InputEvent")

		# Initial values come from serialized data if it exists, default values are what the
		# property gets reset to
		var default_value = value
		var initial_value = serialized_data.get(property_name, default_value)
		config.set(property_name, initial_value)

		if property_usage & PROPERTY_USAGE_EDITOR:
			var label_container := HBoxContainer.new()
			label_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
			var label := Label.new()
			label.tooltip_text = property_key
			label.mouse_filter = Control.MOUSE_FILTER_PASS
			label.text = Util.pretty_print_property(ReverseDNSUtil.pretty_print(property_name))
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			label_container.add_child(label)
			var edit_container := HBoxContainer.new()
			edit_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var reset_button := Button.new()
			reset_button.icon = _RESET_ICON
			label_container.add_child(reset_button)
			var update_reset_button := func():
				var config_value = config.get(property_name)
				if is_shortcut:
					reset_button.visible = not (
						config_value == default_value
						or config_value != null and config_value.is_match(default_value)
					)
				else:
					reset_button.visible = config_value != default_value
			var last_value: Array = [initial_value]
			var delegate := Inspector.create_delegate(
				property, initial_value,
				func(new_value):
					config.set(property_name, new_value)
					last_value[0] = new_value
					any_setting_changed.emit(property_key, default_value)
					_emit_value_changed(property_key, new_value)
					update_reset_button.call()
					serialize.call_deferred()
			)
			data.set_value_funcs[property_name] = delegate.set_value_func
			delegate.control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			update_reset_button.call()
			edit_container.add_child(delegate.control)
			reset_button.pressed.connect(set.bind(property_key, default_value))
			reset_button.pressed.connect(update_reset_button)
			if is_shortcut:
				_shortcut_search_changed.connect(func(filter_text: String, filter_event: InputEvent):
					var failed_filter := false
					if filter_text and not label.text.containsn(filter_text):
						failed_filter = true
					if filter_event and last_value[0] is InputEvent and not filter_event.is_match(last_value[0]):
						failed_filter = true
					label_container.visible = not failed_filter
					edit_container.visible = not failed_filter
				)
				if not has_created_shortcut_header:
					var header_label := Label.new()
					header_label.text = ReverseDNSUtil.pretty_print(config.get_id())
					header_label.theme_type_variation = "HeaderMedium"
					var header_right := Control.new()
					header_right.size_flags_horizontal = Control.SIZE_SHRINK_END
					_shortcut_container.add_child(header_label)
					_shortcut_container.add_child(header_right)
					has_created_shortcut_header = true
				_shortcut_container.add_child(label_container)
				_shortcut_container.add_child(edit_container)
			else:
				has_tree_worthy_properties = true
				grid_container.add_child(label_container)
				grid_container.add_child(edit_container)
	if not has_tree_worthy_properties:
		parent.remove_child(tree_item)
		tree_item.free()

## Returns a signal that is emitted whenever [param property]'s value changes.
## [codeblock]
## Settings.setting_changed("core/ui_scale").connect(func(ui_scale: float):
## 	print(ui_scale)
## )
## [/codeblock]
func setting_changed(property: StringName) -> Signal:
	if property in _signals:
		return _signals[property]
	add_user_signal(property, [{ "name": "new_value" }])
	var s := Signal(self, property)
	_signals[property] = s
	return s


func _get(property: StringName) -> Variant:
	var safe := get_safe(property)
	if not safe: return null
	return safe[0]

## Returns an array either containing the value of [param property] or nothing if it doesn't exist.
func get_safe(property: StringName) -> Array[Variant]:
	var data := property.split("/", true, 2)
	if data.size() != 2:
		return []
	if data[0] in config_data:
		return [config_data[data[0]].config.get(data[1])]
	return []

## Returns [param property] or [param default] if it doesn't exist.
func get_or_default(property: StringName, default: Variant) -> Variant:
	var result := get_safe(property)
	return default if result.is_empty() else result[0]


func _set(property: StringName, value: Variant) -> bool:
	var data := property.split("/", true, 2)
	if data.size() != 2:
		return false
	if data[0] in config_data:
		config_data[data[0]].set_value(data[1], value)
		serialize.call_deferred()
		any_setting_changed.emit(property, value)
		_emit_value_changed(property, value)
		return true
	return false

## Returns whether [param property] exists.
func has(property: StringName) -> bool:
	var data := property.split("/", true, 2)
	if data.size() != 2:
		return false
	return data[0] in config_data and data[1] in config_data[data[0]].config


func _emit_value_changed(property_key: StringName, new_value) -> void:
	if property_key in _signals:
		_signals[property_key].emit(new_value)


func _on_tree_item_selected() -> void:
	var item := _tree.get_selected()
	var id: String = item.get_metadata(0)
	if _settings_container.get_child_count() > 0:
		_settings_container.remove_child(_settings_container.get_child(0))
	_settings_container.add_child(config_data[id].control)

## Force-saves the settings.
func serialize() -> void:
	var config_res := _SettingsSerializer.new()
	config_res.location = Configuration.Location.CONFIG
	config_res.generate_values()
	if not DirAccess.dir_exists_absolute(config_path.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(config_path.get_base_dir())
	ResourceSaver.save(config_res, config_path)
	var local_res := _SettingsSerializer.new()
	local_res.location = Configuration.Location.LOCAL
	local_res.generate_values()
	ResourceSaver.save(local_res, local_path)

## Show the settings window set to the settings tab.
func show_settings() -> void:
	_tab_container.current_tab = 0
	show()


## Show the settings window set to the shortcuts tab.
func show_shortcuts() -> void:
	_tab_container.current_tab = 1
	show()


class ConfigurationData:
	var control: Control
	var config: Configuration
	var set_value_funcs: Dictionary[StringName, Callable]

	func set_value(property: StringName, value) -> void:
		config.set(property, value)
		if property in set_value_funcs:
			set_value_funcs[property].call(value)
