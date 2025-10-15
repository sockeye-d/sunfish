@tool
extends Window


@warning_ignore("unused_private_class_variable")
@export_tool_button("Reload settings", "Reload") var __ := reload_settings


@onready var tree: Tree = %Tree
@onready var settings_container: Container = %SettingsContainer


var config_data: Dictionary[String, ConfigurationData]


func _ready() -> void:
	close_requested.connect(hide)
	if OS.has_feature("mobile"):
		size = Vector2i(500, 275)
		position = (get_tree().root.size / 2 / get_tree().root.content_scale_factor - size / 2.0)
	reload_settings()


func reload_settings() -> void:
	for key in config_data:
		var data := config_data[key]
		data.control.queue_free()
	config_data.clear()
	tree.clear()
	var root := tree.create_item()
	for config in PluginManager.configurations:
		create_settings_for(root, config)


func create_settings_for(parent: TreeItem, config: Configuration) -> void:
	var id := config.get_id()
	var tree_item := parent.create_child()
	var grid_container := GridContainer.new()
	grid_container.columns = 2
	tree_item.set_text(0, ReverseDNSUtil.pretty_print(id))
	tree_item.set_metadata(0, id)
	tree_item.set_tooltip_text(0, id)
	for property in config.get_property_list():
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		var value = config.get(property.name)
		if ClassDB.is_parent_class(property.class_name, "Resource") and value is Configuration:
			create_settings_for(tree_item, value)
		else:
			var label := Label.new()
			label.tooltip_text = id + "/" + property.name
			label.mouse_filter = Control.MOUSE_FILTER_PASS
			label.text = property.name
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var control: Control = Inspector.create_delegate(
				property, value, func(new_value): config.set(property.name, new_value)
			)
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			grid_container.add_child(label)
			grid_container.add_child(control)
	var data := ConfigurationData.new()
	data.config = config
	data.control = grid_container
	config_data[id] = data


class ConfigurationData:
	var control: Control
	var config: Configuration


func _get(property: StringName) -> Variant:
	var data := property.split("/", true, 2)
	if data.size() != 2:
		return null
	if data[0] in config_data:
		return config_data[data[0]].get(data[1])
	return null


func _on_tree_item_selected() -> void:
	var item := tree.get_selected()
	var id: String = item.get_metadata(0)
	settings_container.remove_child(settings_container.get_child(0))
	settings_container.add_child(config_data[id].control)
