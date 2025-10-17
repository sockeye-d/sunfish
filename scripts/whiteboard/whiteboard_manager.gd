@tool
class_name WhiteboardManager


signal tools_changed


static var instance: WhiteboardManager:
	get:
		if not instance:
			instance = WhiteboardManager.new()
		return instance


static var tools: Dictionary[String, Script]
static var passive_tools: Dictionary[String, WhiteboardTool]
static var _deserializers: Dictionary[String, Callable]


static func register_passive_tool(tool: WhiteboardTool) -> void:
	_register_passive_tool.call_deferred(tool)


static func register_tool(tool_script: Script) -> void:
	tools[tool_script.get_id()] = tool_script
	instance.tools_changed.emit.call_deferred()


static func _register_passive_tool(tool: WhiteboardTool) -> void:
	if tool.get_id() not in passive_tools:
		passive_tools[tool.get_id()] = tool


static func register_deserializer(script: Script) -> void:
	register_deserializer_for_id(script.get_id(), script.deserialize)


static func register_deserializer_for_id(id: String, deserializer: Callable) -> void:
	_deserializers[id] = deserializer


static func serialize(elements: Array[WhiteboardTool.Element]) -> Dictionary:
	var element_data: Array[Dictionary]
	
	for element in elements:
		element_data.append({
			"id": element.get_script().get_id(),
			"data": element.serialize()
		})
	
	return {
		"version": 1,
		"elements": element_data,
	}


static func deserialize(data: Dictionary) -> Array[WhiteboardTool.Element]:
	var elements: Array[WhiteboardTool.Element]
	for element in data.elements:
		elements.append(_deserializers[element.id].call(element.data))
	return elements
