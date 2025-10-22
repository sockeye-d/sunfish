@tool
class_name ToolPopup extends PopupPanel


signal active_tool_changed(new_tool: Script)


var tool_button_group := ButtonGroup.new()
var tool_instances: Dictionary[Script, WhiteboardTool]


@export var whiteboard: Whiteboard
@warning_ignore("unused_private_class_variable")
@export_tool_button("Update tools") var __ := _update_tools


var tools: Dictionary[Script, ToolButtonState]
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


func _update_tools() -> void:
	for tool in tools:
		if tool in tools:
			tools[tool].queue_free()
		else:
			tools.erase(tool)
	tools.clear()
	if WhiteboardManager.tools.is_empty():
		return
	for tool_id in WhiteboardManager.tools:
		var tool := WhiteboardManager.tools[tool_id]
		if not tool.is_visible():
			continue
		var state := ToolButtonState.new()
		var icon := IconTexture2D.create(tool.get_id())
		state.icon = icon
		state.tool = tool
		tools[tool] = state


func set_selected(tool: Script) -> void:
	tools[tool].button_pressed = true


class ToolButtonState:
	var icon: Texture2D
	var tool: Script
	var hovered: bool


class Visual extends Control:
	var t: ToolPopup
	
	
	func _draw() -> void:
		var index := 0
		for tool_id in t.tools:
			var angle := index * TAU / t.tools.size()
			var state := t.tools[tool_id]
			
			index += 1
