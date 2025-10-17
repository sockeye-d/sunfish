class_name Shortcuts

static func create(action_name: String) -> Shortcut:
	var obj := Shortcut.new()
	var input_event := InputEventAction.new()
	input_event.action = action_name
	obj.events = [input_event]
	return obj
