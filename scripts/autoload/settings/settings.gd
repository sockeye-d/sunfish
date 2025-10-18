@tool
extends Window

signal any_setting_changed(property: String, new_value)

const RESET_ICON = preload("uid://dmah5fp6rgtqt")
const SettingsResource = preload("uid://dat0ps77q50u2")

static var config_path := OS.get_config_dir().path_join("sunfish/settings.tres")


@onready var tree: Tree = %Tree
@onready var settings_container: Container = %SettingsContainer
@onready var shortcut_container: GridContainer = %ShortcutContainer
@onready var keep: Array[Node] = [%NameLabel, %BindingLabel]


var config_data: Dictionary[String, ConfigurationData]
var signals: Dictionary[String, Signal]
var serializers: Dictionary[Variant, Dictionary]
var deserializers: Dictionary[String, Variant]


func _ready() -> void:
	close_requested.connect(hide)
	if OS.has_feature("mobile"):
		size = Vector2i(500, 275)
		position = (get_tree().root.size / 2 / get_tree().root.content_scale_factor - size / 2.0)
	#var peer := StreamPeerFile.open(config_path, FileAccess.READ)
	#var serialized_data = JSON.parse_string(peer.get_utf8_string(peer.get_available_bytes())) if peer else {}
	var obj = ResourceLoader.load(config_path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	if obj:
		obj.obj = self
	else:
		print("couldn't load settings")
		obj = {}
	reload_settings(obj)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()


func reload_settings(serialized_data) -> void:
	for key in config_data:
		var data := config_data[key]
		data.control.queue_free()
	for child in shortcut_container.get_children():
		if child in keep:
			continue
		child.queue_free()
	config_data.clear()
	tree.clear()
	var root := tree.create_item()
	for config in PluginManager.configurations:
		create_settings_for(root, config, serialized_data)


func create_settings_for(parent: TreeItem, config: Configuration, serialized_data) -> void:
	var id := config.get_id()
	var tree_item := parent.create_child()
	var grid_container := GridContainer.new()
	grid_container.columns = 2
	tree_item.set_text(0, ReverseDNSUtil.pretty_print(id))
	tree_item.set_metadata(0, id)
	tree_item.set_tooltip_text(0, id)
	var has_visible_properties := false
	for property in config.get_property_list():
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE or not property.usage & PROPERTY_USAGE_STORAGE:
			continue
		var property_name: String = property.name
		var value = config.get(property_name)
		var property_key := id + "/" + property_name
		var is_shortcut := ClassDB.is_parent_class(property.class_name, "InputEvent")
		if ClassDB.is_parent_class(property.class_name, "Resource") and value is Configuration:
			create_settings_for(tree_item, value, serialized_data)
		else:
			var initial_value = value
			var default_value = initial_value
			if id in serialized_data and property_name in serialized_data[id]:
				initial_value = serialized_data[id][property_name]
				config.set(property_name, initial_value)

			if property.usage & PROPERTY_USAGE_EDITOR:
				has_visible_properties = true
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
					reset_button.visible = config.get(property_name) != default_value
				var create_control := func(prop_value):
					var ctl := Inspector.create_delegate(
						property, prop_value,
						func(new_value):
							config.set(property_name, new_value)
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
					_emit_value_changed(property_key, default_value)
					any_setting_changed.emit(property_key, default_value)
					control[0] = create_control.call(default_value)
					edit_container.add_child(control[0])
					update_reset_button.call()
					serialize.call_deferred()
				)
				if is_shortcut:
					shortcut_container.add_child(label)
					shortcut_container.add_child(edit_container)
				else:
					grid_container.add_child(label)
					grid_container.add_child(edit_container)
	var data := ConfigurationData.new()
	data.config = config
	data.control = grid_container
	config_data[id] = data
	if not has_visible_properties:
		parent.remove_child(tree_item)
		tree_item.free()


func setting_changed(setting_id: String) -> Signal:
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
	var data := property.split("/", true, 2)
	if data.size() != 2:
		return null
	if data[0] in config_data:
		return config_data[data[0]].config.get(data[1])
	return null


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


func _emit_value_changed(property_key: String, new_value) -> void:
	if property_key in signals:
		signals[property_key] = new_value


func _on_tree_item_selected() -> void:
	var item := tree.get_selected()
	var id: String = item.get_metadata(0)
	if settings_container.get_child_count() > 0:
		settings_container.remove_child(settings_container.get_child(0))
	settings_container.add_child(config_data[id].control)


func serialize(path: String = config_path) -> void:
	var res := SettingsResource.new()
	res.obj = self
	res.save(path)


func register_serializer(type, serializer: Dictionary[String, Variant]) -> void:
	serializers[type] = serializer


func register_deserializer(type, serializer: Dictionary[String, Variant]) -> void:
	serializers[type] = serializer
