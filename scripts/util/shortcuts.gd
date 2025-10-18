class_name Shortcuts

static func create(action_name: String) -> Shortcut:
	var obj := Shortcut.new()
	var input_event := InputEventAction.new()
	input_event.action = action_name
	obj.events = [input_event]
	return obj


static func key(keycode: Key, mods: KeyModifierMask) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = keycode
	e.alt_pressed = mods & KEY_MASK_ALT
	e.ctrl_pressed = mods & KEY_MASK_CTRL
	e.meta_pressed = mods & KEY_MASK_META
	e.shift_pressed = mods & KEY_MASK_SHIFT
	return e
