extends Window


static var _remove_icon := IconTexture2D.create("delete_red")


@onready var plugin_container: VBoxContainer = %PluginContainer
@onready var install_from_file_button: Button = %InstallFromFileButton
@onready var restart_confirmation_dialog: ConfirmationDialog = %RestartConfirmationDialog


var plugin_controls: Dictionary[PluginManager.PluginData, Control]
var needs_to_restart: bool = false


func _ready() -> void:
	close_requested.connect(close)
	files_dropped.connect(func(files: PackedStringArray) -> void:
		for file in files:
			PluginManager.add_plugin(file)
	)

	for plugin in PluginManager.plugins:
		plugin_container.add_child(create_plugin_control(plugin, false))

	PluginManager.instance.plugin_added.connect(func(plugin: PluginManager.PluginData):
		plugin_container.add_child(create_plugin_control(plugin))
		_update_restart_status()
	)

	PluginManager.instance.plugin_removed.connect(func(plugin: PluginManager.PluginData):
		plugin_controls[plugin].queue_free()
		plugin_controls.erase(plugin)
		_update_restart_status()
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()


func close() -> void:
	if needs_to_restart:
		restart_confirmation_dialog.popup()
	else:
		hide()


func create_plugin_control(data: PluginManager.PluginData, just_loaded: bool = true) -> Control:
	var container := HBoxContainer.new()
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = data.name
	if just_loaded:
		label.theme_type_variation = "SubtextLabel"
	var check_box := CheckBox.new()
	check_box.toggle_mode = true
	check_box.button_pressed = data.enabled
	check_box.toggled.connect(func(state: bool):
		data.enabled = state
		_update_restart_status()
	)
	var remove_button := Button.new()
	remove_button.icon = _remove_icon
	remove_button.pressed.connect(func():
		PluginManager.remove_plugin(data)
	)
	container.add_child(label)
	container.add_child(check_box)
	container.add_child(remove_button)
	plugin_controls[data] = container
	return container


func _update_restart_status() -> void:
	needs_to_restart = PluginManager.are_plugins_changed()


func _on_restart_confirmation_dialog_canceled() -> void:
	hide()


func _on_restart_confirmation_dialog_confirmed() -> void:
	TreeEvents.restart()
