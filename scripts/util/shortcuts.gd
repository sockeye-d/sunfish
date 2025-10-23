class_name Shortcuts
## Utility for creating [class Shortcut]s.

## Create a new Shortcut object from the given settings [param property_id]
static func create(property_id: String) -> Shortcut:
	var obj := Shortcut.new()
	var target_input_event: InputEvent = Settings.get_safe(property_id)[0]
	var set_event := func(new_value: InputEvent) -> void:
		obj.events = [new_value]
	Settings.setting_changed(property_id).connect(set_event)
	set_event.call(target_input_event)
	#obj.events = [input_event]
	return obj

## Create a new InputEvent from the given [param keycode] and [param mods].
static func key(keycode: Key, mods: KeyModifierMask = 0 as KeyModifierMask) -> InputEvent:
	var e := InputEventKey.new()
	e.keycode = keycode
	e.alt_pressed = mods & KEY_MASK_ALT
	e.ctrl_pressed = mods & KEY_MASK_CTRL
	e.meta_pressed = mods & KEY_MASK_META
	e.shift_pressed = mods & KEY_MASK_SHIFT
	return e
