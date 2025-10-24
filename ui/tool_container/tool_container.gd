@tool
class_name ToolContainer extends Control


signal active_tool_changed(new_tool: Script)


var tool_button_group := ButtonGroup.new()
var tool_instances: Dictionary[Script, WhiteboardTool]


@export var whiteboard: Whiteboard
@warning_ignore("unused_private_class_variable")
@export_tool_button("Update tools") var __ := _update_tools


var tool_buttons: Dictionary[Script, Button]
var selected_tool_id: String


func _ready() -> void:
	active_tool_changed.connect(func(new_tool: Script):
		if whiteboard:
			if new_tool not in tool_instances:
				tool_instances[new_tool] = new_tool.new()
			whiteboard.set_active_tools([tool_instances[new_tool]])
	)
	WhiteboardManager.instance.tools_changed.connect(_update_tools)
	selected_tool_id = Settings["core/default_tool"]
	_update_tools.call_deferred()
	whiteboard.tool_popup.tool_selected.connect(func(tool: Script):
		active_tool_changed.emit(tool)
		tool_buttons[tool].button_pressed = true
	)

	whiteboard.gui_input.connect(_whiteboard_gui_input)


func _whiteboard_gui_input(event: InputEvent) -> void:
	for tool_id in WhiteboardManager.tools:
		var setting_key := "shortcuts.tools/" + tool_id
		var shortcut_event := Settings.get_safe(setting_key)
		if not shortcut_event.is_empty() and shortcut_event[0] != null:
			if event.is_match(shortcut_event[0]):
				var tool := WhiteboardManager.tools[tool_id]
				active_tool_changed.emit(tool)
				tool_buttons[tool].button_pressed = true
				whiteboard.accept_event()
				return


func _update_tools() -> void:
	for tool in tool_buttons:
		tool_buttons[tool].queue_free()
	tool_buttons.clear()
	if WhiteboardManager.tools.is_empty():
		return
	for tool_id in WhiteboardManager.tools:
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
	whiteboard.tool_popup._update_tools()


func set_selected(tool: Script) -> void:
	tool_buttons[tool].button_pressed = true
