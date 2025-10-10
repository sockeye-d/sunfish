@tool
class_name ToolContainer extends VFlowContainer


signal active_tool_changed(new_tool: Script)


var tool_button_group := ButtonGroup.new()


@export var tools: Array[Script]
@export var whiteboard: Whiteboard
@warning_ignore("unused_private_class_variable")
@export_tool_button("Update tools") var __ := _update_tools


func _ready() -> void:
	_update_tools()
	active_tool_changed.connect(func(new_tool: Script):
		whiteboard.set_active_tools([new_tool.new()])
	)


func _update_tools() -> void:
	for child in get_children():
		child.queue_free()
	for tool in tools:
		if not tool.is_visible():
			continue
		var btn := Button.new()
		var icon := IconTexture2D.new()
		icon.icon = "tools/" + tool.get_id()
		icon.icon_scale = 1.5
		btn.toggle_mode = true
		btn.icon = icon
		btn.button_group = tool_button_group
		
		btn.pressed.connect(active_tool_changed.emit.bind(tool))
		add_child(btn)
