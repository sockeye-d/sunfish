class_name Shortcuts


static func create(property_id: String) -> Shortcut:
	var obj := Shortcut.new()
	#var input_event := InputEventKey.new()
	var target_input_event: InputEventKey = Settings.get_safe(property_id)[0]
	var set_event := func(new_value: InputEventKey) -> void:
		#input_event.keycode = new_value.keycode
		#input_event.alt_pressed = new_value.alt_pressed
		#input_event.ctrl_pressed = new_value.ctrl_pressed
		#input_event.meta_pressed = new_value.meta_pressed
		#input_event.shift_pressed = new_value.shift_pressed
		#obj.emit_changed()
		obj.events = [new_value]
	Settings.setting_changed(property_id).connect(set_event)
	set_event.call(target_input_event)
	#obj.events = [input_event]
	return obj


static func key(keycode: Key, mods: KeyModifierMask) -> InputEvent:
	var e := InputEventKey.new()
	e.keycode = keycode
	e.alt_pressed = mods & KEY_MASK_ALT
	e.ctrl_pressed = mods & KEY_MASK_CTRL
	e.meta_pressed = mods & KEY_MASK_META
	e.shift_pressed = mods & KEY_MASK_SHIFT
	return e
