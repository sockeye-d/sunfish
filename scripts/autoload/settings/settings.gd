@tool
extends Window

signal any_setting_changed(property: StringName, new_value)

signal _shortcut_search_changed(text_filter: String, event_filter: InputEvent)

const RESET_ICON = preload("uid://dmah5fp6rgtqt")
const SettingsSerializer = preload("uid://cphoy3o8egue5")

var config_path := OS.get_config_dir().path_join("sunfish/settings.tres")
var local_path := OS.get_user_data_dir().path_join("state.tres")


@onready var tree: Tree = %Tree
@onready var settings_container: Container = %SettingsContainer
@onready var shortcut_container: GridContainer = %ShortcutContainer
@onready var shortcut_search_text: LineEdit = %ShortcutSearchText
@onready var shortcut_search_event: EventInput = %ShortcutSearchEvent
@onready var tab_container: TabContainer = %TabContainer


var config_data: Dictionary[StringName, ConfigurationData]
var signals: Dictionary[StringName, Signal]
var has_deserialized := false


func _ready() -> void:
	close_requested.connect(hide)
	if OS.has_feature("mobile"):
		size = Vector2i(500, 275)
		position = get_tree().root.size / 2.0 / get_tree().root.content_scale_factor - size / 2.0
	var deserialized_settings := SettingsSerializer.merge(_load(config_path), _load(local_path))
	reload_settings(deserialized_settings)
	has_deserialized = true
	shortcut_search_text.text_changed.connect(_emit_shortcut_search_changed)
	shortcut_search_event.event_changed.connect(_emit_shortcut_search_changed)


func _load(path: String) -> SettingsSerializer:
	if not FileAccess.file_exists(path):
		return null
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)


func _emit_shortcut_search_changed(_v) -> void:
	_shortcut_search_changed.emit(shortcut_search_text.text, shortcut_search_event.last_event)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()


func reload_settings(serialized_data: Dictionary[StringName, Dictionary]) -> void:
	const EMPTY_DATA: Dictionary[StringName, Variant] = {}
	for key in config_data:
		var data := config_data[key]
		data.control.queue_free()
	for child in shortcut_container.get_children():
		child.queue_free()
	config_data.clear()
	tree.clear()
	var root := tree.create_item()
	for config in PluginManager.configurations:
		create_settings_for(root, PluginManager.configurations[config], serialized_data.get(config, EMPTY_DATA))


func create_settings_for(parent: TreeItem, config: Configuration, serialized_data: Dictionary[StringName, Variant]) -> void:
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
		if SettingsSerializer.get_serialization_mode(property) <= SettingsSerializer.SerializationMode.NONE:
			continue
		var property_name: StringName = property.name
		var property_class: StringName = property.class_name

		# Check for a custom property revert value, and if it doesn't exist, check for an initial
		# value (like from a setter)
		var value = config.property_get_revert(property_name)
		if value == null: value = config.get(property_name)

		var property_key := StringName(id + "/" + property_name)
		var is_shortcut := ClassDB.is_parent_class(property_class, "InputEvent")

		# Initial values come from serialized data if it exists, default values are what the
		# property gets reset to
		var initial_value = value
		var default_value = value
		if property_name in serialized_data:
			initial_value = serialized_data[property_name]
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
			reset_button.icon = RESET_ICON
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
					label.visible = not failed_filter
					edit_container.visible = not failed_filter
				)
				if not has_created_shortcut_header:
					var header_label := Label.new()
					header_label.text = ReverseDNSUtil.pretty_print(config.get_id())
					header_label.theme_type_variation = "HeaderMedium"
					var header_right := Control.new()
					header_right.size_flags_horizontal = Control.SIZE_SHRINK_END
					shortcut_container.add_child(header_label)
					shortcut_container.add_child(header_right)
					has_created_shortcut_header = true
				shortcut_container.add_child(label_container)
				shortcut_container.add_child(edit_container)
			else:
				has_tree_worthy_properties = true
				grid_container.add_child(label_container)
				grid_container.add_child(edit_container)
	if not has_tree_worthy_properties:
		parent.remove_child(tree_item)
		tree_item.free()


func setting_changed(setting_id: StringName) -> Signal:
	if setting_id in signals:
		return signals[setting_id]
	add_user_signal(setting_id, [{ "name": "new_value" }])
	var s := Signal(self, setting_id)
	signals[setting_id] = s
	return s


class ConfigurationData:
	var control: Control
	var config: Configuration
	var set_value_funcs: Dictionary[StringName, Callable]

	func set_value(property: StringName, value) -> void:
		config.set(property, value)
		if property in set_value_funcs:
			set_value_funcs[property].call(value)


func _get(property: StringName) -> Variant:
	var safe := get_safe(property)
	if not safe: return null
	return safe[0]


func get_safe(property: StringName) -> Array[Variant]:
	var data := property.split("/", true, 2)
	if data.size() != 2:
		return []
	if data[0] in config_data:
		return [config_data[data[0]].config.get(data[1])]
	return []


func get_default(property: StringName, default: Variant) -> Variant:
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


func has(property_id: StringName) -> bool:
	var data := property_id.split("/", true, 2)
	if data.size() != 2:
		return false
	return data[0] in config_data and data[1] in config_data[data[0]].config


func _emit_value_changed(property_key: StringName, new_value) -> void:
	if property_key in signals:
		signals[property_key].emit(new_value)


func _on_tree_item_selected() -> void:
	var item := tree.get_selected()
	var id: String = item.get_metadata(0)
	if settings_container.get_child_count() > 0:
		settings_container.remove_child(settings_container.get_child(0))
	settings_container.add_child(config_data[id].control)


func serialize() -> void:
	var config_res := SettingsSerializer.new()
	config_res.location = Configuration.Location.CONFIG
	config_res.generate_values()
	if not DirAccess.dir_exists_absolute(config_path.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(config_path.get_base_dir())
	ResourceSaver.save(config_res, config_path)
	var local_res := SettingsSerializer.new()
	local_res.location = Configuration.Location.LOCAL
	local_res.generate_values()
	ResourceSaver.save(local_res, local_path)


func show_settings() -> void:
	tab_container.current_tab = 0
	show()


func show_shortcuts() -> void:
	tab_container.current_tab = 1
	show()
