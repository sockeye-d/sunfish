class_name WhiteboardTools


static var _deserializers: Dictionary[String, Callable]


static func register_deserializer(script: Script) -> void:
	_deserializers[script.get_id()] = script.deserialize


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
