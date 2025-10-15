@tool
class_name ToolContainer extends Control


signal active_tool_changed(new_tool: Script)


var tool_button_group := ButtonGroup.new()
var tool_instances: Dictionary[Script, WhiteboardTool]


@export var tools: Array[Script]
@export var whiteboard: Whiteboard
@warning_ignore("unused_private_class_variable")
@export_tool_button("Update tools") var __ := _update_tools


var tool_buttons: Dictionary[Script, Button]


func _ready() -> void:
	active_tool_changed.connect(func(new_tool: Script):
		if whiteboard:
			if new_tool not in tool_instances:
				tool_instances[new_tool] = new_tool.new()
			whiteboard.set_active_tools([tool_instances[new_tool]])
	)
	_update_tools.call_deferred()


func _update_tools() -> void:
	for tool in tool_buttons:
		if tool in tool_buttons:
			tool_buttons[tool].queue_free()
		else:
			tool_buttons.erase(tool)
	tool_buttons.clear()
	if tools.is_empty():
		return
	for tool in tools:
		if not tool.is_visible():
			continue
		var btn := Button.new()
		var icon := IconTexture2D.new()
		icon.icon = tool.get_id()
		icon.icon_scale = 1.5
		btn.toggle_mode = true
		btn.icon = icon
		btn.button_group = tool_button_group
		
		tool_buttons[tool] = btn
		btn.pressed.connect(active_tool_changed.emit.bind(tool))
		add_child(btn)
	
	active_tool_changed.emit(tools.front())
	tool_buttons[tools.front()].button_pressed = true
