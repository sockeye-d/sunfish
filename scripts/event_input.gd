@tool
class_name EventInput extends HBoxContainer


signal event_changed(event: InputEvent)
signal event_submitted(event: InputEvent)


static var clear_icon: IconTexture2D:
	get:
		if not clear_icon:
			clear_icon = IconTexture2D.new()
			clear_icon.icon = "clear"
		return clear_icon


var last_event: InputEvent


func _init(initial_value: InputEvent = null) -> void:
	var event_btn := Button.new()
	var clear_btn := Button.new()
	clear_btn.icon = clear_icon
	event_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(event_btn)
	add_child(clear_btn)
	event_btn.text = initial_value.as_text() if initial_value != null else "(Unset)"
	event_btn.toggle_mode = true
	var btn_gui_input := func(event: InputEvent):
		if event is InputEventKey and event.is_pressed() and not event.is_echo():
			last_event = event
			event_btn.text = event.as_text()
			event_btn.accept_event()
			event_changed.emit(last_event)
	var btn_lost_input := func():
		event_btn.button_pressed = false
		if event_btn.gui_input.is_connected(btn_gui_input):
			event_btn.gui_input.disconnect(btn_gui_input)
		if last_event:
			event_changed.emit(last_event)
			event_submitted.emit(last_event)
	event_btn.toggled.connect(func(state: bool):
		if state:
			event_btn.focus_exited.connect(btn_lost_input, CONNECT_ONE_SHOT)
			event_btn.gui_input.connect(btn_gui_input)
		else:
			btn_lost_input.call()
			event_btn.focus_exited.disconnect(btn_lost_input)
	)
	clear_btn.pressed.connect(func():
		last_event = null
		event_changed.emit(null)
		event_submitted.emit(null)
		event_btn.text = "(Unset)"
	)
