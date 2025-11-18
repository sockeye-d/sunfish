@tool
class_name ToolContainer extends Control


signal active_tool_changed(new_tool: Script)


var tool_button_group := ButtonGroup.new()
var tool_instances: Dictionary[Script, WhiteboardTool]


@export var whiteboard: Whiteboard
@export var edit_button: Button
@warning_ignore("unused_private_class_variable")
@export_tool_button("Update tools") var __ := update_tools


var tool_buttons: Dictionary[Script, Button]
var selected_tool_id: String
var tool_popup := ToolPopup.new()


func _init() -> void:
	WhiteboardManager.register_radial_popup(tool_popup, "shortcuts/show_tool_pie")


func _ready() -> void:
	active_tool_changed.connect(func(new_tool: Script):
		if whiteboard:
			if new_tool not in tool_instances:
				tool_instances[new_tool] = new_tool.new()
			whiteboard.set_active_tools([tool_instances[new_tool]])
			tool_popup.selected_tools = [tool_instances[new_tool].get_script()]
	)
	selected_tool_id = Settings["core/default_tool"]
	update_tools.call_deferred()
	tool_popup.item_selected.connect(func(item: ToolPopup.ToolItem):
		active_tool_changed.emit(item.tool)
		tool_buttons[item.tool].button_pressed = true
	)

	whiteboard.gui_input.connect(_whiteboard_gui_input)
	Settings.setting_changed("core/tool_layout").connect(func(_new_value): update_tools())


func _whiteboard_gui_input(event: InputEvent) -> void:
	for tool_id: StringName in Settings["core/tool_layout"]:
		var setting_key := "shortcuts.tools/" + tool_id
		var shortcut_event := Settings.get_safe(setting_key)
		if not shortcut_event.is_empty() and shortcut_event[0] != null:
			if event.is_match(shortcut_event[0]):
				var tool := WhiteboardManager.tools[tool_id]
				active_tool_changed.emit(tool)
				tool_buttons[tool].button_pressed = true
				whiteboard.accept_event()
				return


func update_tools() -> void:
	for tool in tool_buttons:
		tool_buttons[tool].queue_free()
	tool_buttons.clear()
	if Settings["core/tool_layout"].is_empty():
		return
	for tool_id: StringName in Settings["core/tool_layout"]:
		var tool := WhiteboardManager.tools[tool_id]
		if not tool.is_visible():
			continue
		var btn := Button.new()
		var icon := IconTexture2D.create(tool.get_id())
		btn.toggle_mode = true
		btn.icon = icon
		btn.button_group = tool_button_group

		if selected_tool_id == tool_id:
			btn.button_pressed = true
			active_tool_changed.emit(tool)

		tool_buttons[tool] = btn
		btn.pressed.connect(func():
			selected_tool_id = tool_id
			active_tool_changed.emit(tool)
		)
		add_child(btn)
	tool_popup.update_tools()


func set_selected(tool: Script) -> void:
	tool_buttons[tool].button_pressed = true
