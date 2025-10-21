@tool
extends Window

signal any_setting_changed(property: StringName, new_value)

signal _shortcut_search_changed(text_filter: String, event_filter: InputEvent)

const RESET_ICON = preload("uid://dmah5fp6rgtqt")
const SettingsSerializer = preload("uid://cphoy3o8egue5")

var config_path := OS.get_config_dir().path_join("sunfish/settings.tres")


@onready var tree: Tree = %Tree
@onready var settings_container: Container = %SettingsContainer
@onready var shortcut_container: GridContainer = %ShortcutContainer
@onready var shortcut_search_text: LineEdit = %ShortcutSearchText
@onready var shortcut_search_event: EventInput = %ShortcutSearchEvent


var config_data: Dictionary[StringName, ConfigurationData]
var signals: Dictionary[StringName, Signal]
var has_deserialized := false


func _ready() -> void:
	close_requested.connect(hide)
	if OS.has_feature("mobile"):
		size = Vector2i(500, 275)
		position = get_tree().root.size / 2.0 / get_tree().root.content_scale_factor - size / 2.0
	reload_settings(ResourceLoader.load(config_path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as SettingsSerializer)
	has_deserialized = true
	shortcut_search_text.text_changed.connect(_emit_shortcut_search_changed)
	shortcut_search_event.event_changed.connect(_emit_shortcut_search_changed)


func _emit_shortcut_search_changed(_v) -> void:
	_shortcut_search_changed.emit(shortcut_search_text.text, shortcut_search_event.last_event)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()


func reload_settings(serialized_data: SettingsSerializer) -> void:
	for key in config_data:
		var data := config_data[key]
		data.control.queue_free()
	for child in shortcut_container.get_children():
		child.queue_free()
	config_data.clear()
	tree.clear()
	var root := tree.create_item()
	for config in PluginManager.configurations:
		create_settings_for(root, PluginManager.configurations[config], serialized_data)


func create_settings_for(parent: TreeItem, config: Configuration, serialized_data: SettingsSerializer) -> void:
	var id := config.get_id()
	var tree_item := parent.create_child()
	var grid_container := GridContainer.new()
	grid_container.columns = 2
	tree_item.set_text(0, ReverseDNSUtil.pretty_print(id))
	tree_item.set_metadata(0, id)
	tree_item.set_tooltip_text(0, id)
	var has_tree_worthy_properties := false
	for property in config.get_property_list():
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE or not property.usage & PROPERTY_USAGE_STORAGE:
			continue
		var property_name: StringName = property.name
		var value = config.get(property_name)
		var property_key := StringName(id + "/" + property_name)
		var is_shortcut := ClassDB.is_parent_class(property.class_name, "InputEvent")
		if ClassDB.is_parent_class(property.class_name, "Resource") and value is Configuration:
			create_settings_for(tree_item, value, serialized_data)
		else:
			var initial_value = value
			var default_value = initial_value
			if serialized_data and serialized_data.has(property_key):
				initial_value = serialized_data.get_safe(property_key)
				config.set(property_name, initial_value)

			if property.usage & PROPERTY_USAGE_EDITOR:
				var label := Label.new()
				label.tooltip_text = property_key
				label.mouse_filter = Control.MOUSE_FILTER_PASS
				label.text = Util.pretty_print_property(property_name)
				label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var edit_container := HBoxContainer.new()
				edit_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var reset_button := Button.new()
				reset_button.icon = RESET_ICON
				edit_container.add_child(reset_button)
				var update_reset_button := func():
					var config_value = config.get(property_name)
					if is_shortcut:
						reset_button.visible = not (config_value == default_value or config_value != null and (config_value).is_match(default_value))
					else:
						reset_button.visible = config_value != default_value
				var last_value: Array = [initial_value]
				var create_control := func(prop_value):
					var ctl := Inspector.create_delegate(
						property, prop_value,
						func(new_value):
							config.set(property_name, new_value)
							last_value[0] = new_value
							any_setting_changed.emit(property_key, default_value)
							_emit_value_changed(property_key, new_value)
							update_reset_button.call()
							serialize.call_deferred()
					)
					ctl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					return ctl
				update_reset_button.call()
				var control: Array[Control] = [create_control.call(initial_value)]
				edit_container.add_child(control[0])
				reset_button.pressed.connect(func():
					edit_container.remove_child(control[0])
					config.set(property_name, default_value)
					last_value[0] = default_value
					_emit_value_changed(property_key, default_value)
					any_setting_changed.emit(property_key, default_value)
					control[0] = create_control.call(default_value)
					edit_container.add_child(control[0])
					update_reset_button.call()
					serialize.call_deferred()
				)
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
					shortcut_container.add_child(label)
					shortcut_container.add_child(edit_container)
				else:
					has_tree_worthy_properties = true
					grid_container.add_child(label)
					grid_container.add_child(edit_container)
	var data := ConfigurationData.new()
	data.config = config
	data.control = grid_container
	config_data[id] = data
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


func _set(property: StringName, value: Variant) -> bool:
	var data := property.split("/", true, 2)
	if data.size() != 2:
		return false
	if data[0] in config_data:
		config_data[data[0]].config.set(data[1], value)
		serialize.call_deferred()
		any_setting_changed.emit(property, value)
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


func serialize(path: String = config_path) -> void:
	var res := SettingsSerializer.new()
	res.generate_values()
	ResourceSaver.save(res, path)
