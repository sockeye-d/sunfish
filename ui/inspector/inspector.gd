class_name Inspector extends PanelContainer

enum {
	PROPERTY_HINT_EXT_PRETTY_RDNS_ENUM = 256,
}

static var clear_icon: IconTexture2D:
	get:
		if not clear_icon:
			clear_icon = IconTexture2D.new()
			clear_icon.icon = "clear"
		return clear_icon

## [codeblock]
## Dictionary[PropertyHint, Callable[prop: Dictionary, intitial_value: Variant, set_prop: Callable[new_value: Variant]]]
##
## var delegate: Control = hint_delegates[property.hint].call(
## 	property, tool.get(property.name),
## 	func(new_value): tool.set(property.name, convert(new_value, property.type))
## )
## [/codeblock]
static var hint_delegates: Dictionary[int, Callable] = {
	PROPERTY_HINT_NONE: func(prop: Dictionary, initial_value, set_prop: Callable) -> Control:
		match prop.type as Variant.Type:
			TYPE_BOOL:
				var checkbox := CheckBox.new()
				checkbox.button_pressed = initial_value
				checkbox.toggled.connect(set_prop)
				return checkbox
			_:
				var line_edit := LineEdit.new()
				line_edit.text = str(initial_value)
				line_edit.text_submitted.connect(func(new_text: String): set_prop.call(convert(new_text, prop.type)))
				return line_edit
		,
	PROPERTY_HINT_RANGE: func(prop: Dictionary, initial_value, set_prop: Callable) -> Control:
		assert(prop.type in [TYPE_INT, TYPE_FLOAT])
		var data := (prop.hint_string as String).split(",", true, 4)
		var min_value := float(data[0])
		var max_value := float(data[1])
		var step := float(data[2])
		var extra_hints := data[3].split(",") if data.size() >= 4 else PackedStringArray()
		
		var slider := SliderCombo.new()
		slider.slider_value = initial_value
		slider.min_value = min_value
		slider.max_value = max_value
		slider.step = maxf(step, 0.01)
		slider.allow_greater = "or_greater" in extra_hints
		slider.allow_lesser = "or_less" in extra_hints
		slider.changed.emit()
		slider.slider_value_changed.connect(set_prop)
		return slider,
	PROPERTY_HINT_ENUM: func(prop: Dictionary, initial_value, set_prop: Callable) -> Control:
		assert(prop.type in [TYPE_INT, TYPE_STRING])
		var options := (prop.hint_string as String).split(",")
		var btn := OptionButton.new()
		btn.fit_to_longest_item = false
		for op in options:
			btn.add_item(op)
		btn.item_selected.connect(func(index: int) -> void:
			if prop.type == TYPE_INT:
				set_prop.call(index)
			elif prop.type == TYPE_STRING:
				set_prop.call(options[index])
		)
		if prop.type == TYPE_INT:
			btn.selected = initial_value
		elif prop.type == TYPE_STRING:
			btn.selected = options.find(initial_value)
		return btn,
	PROPERTY_HINT_RESOURCE_TYPE: func(prop: Dictionary, initial_value, set_prop: Callable) -> Control:
		var type: String = prop.hint_string
		match type:
			"InputEvent":
				var event_btn := Button.new()
				var clear_btn := Button.new()
				clear_btn.icon = clear_icon
				event_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var container := HBoxContainer.new()
				container.add_child(event_btn)
				container.add_child(clear_btn)
				event_btn.text = (initial_value as InputEvent).as_text() if initial_value is InputEvent else "(Unset)"
				event_btn.toggle_mode = true
				var last_event: Array[InputEvent] = [null]
				var btn_gui_input := func(event: InputEvent):
					if event is InputEventKey and event.is_pressed() and not event.is_echo():
						last_event[0] = event
						event_btn.text = event.as_text()
						event_btn.accept_event()
				var btn_lost_input := func():
					event_btn.button_pressed = false
					event_btn.gui_input.disconnect(btn_gui_input)
					if last_event[0]:
						set_prop.call(last_event[0])
				event_btn.toggled.connect(func(state: bool):
					if state:
						event_btn.focus_exited.connect(btn_lost_input, CONNECT_ONE_SHOT)
						event_btn.gui_input.connect(btn_gui_input)
					else:
						btn_lost_input.call()
						event_btn.focus_exited.disconnect(btn_lost_input)
				)
				clear_btn.pressed.connect(func():
					set_prop.call(null)
					event_btn.text = "(Unset)"
				)
				return container
		return null,
	PROPERTY_HINT_EXT_PRETTY_RDNS_ENUM: func(prop: Dictionary, initial_value, set_prop: Callable) -> Control:
		assert(prop.type in [TYPE_INT, TYPE_STRING])
		var options := (prop.hint_string as String).split(",")
		var btn := OptionButton.new()
		btn.fit_to_longest_item = false
		for op in options:
			btn.add_item(ReverseDNSUtil.pretty_print(op))
		btn.item_selected.connect(func(index: int) -> void:
			if prop.type == TYPE_INT:
				set_prop.call(index)
			elif prop.type == TYPE_STRING:
				set_prop.call(options[index])
			btn.tooltip_text = options[index]
		)
		if prop.type == TYPE_INT:
			btn.selected = initial_value
		elif prop.type == TYPE_STRING:
			btn.selected = options.find(initial_value)
		if btn.selected != -1:
			btn.tooltip_text = options[btn.selected]
		return btn
}


var tools: Array[WhiteboardTool]:
	set(value):
		tools = value
		_update_inspector()
@export var whiteboard: Whiteboard


@onready var scroll_container: ScrollContainer = %ScrollContainer


var inner_container: VBoxContainer


func _ready() -> void:
	if whiteboard:
		whiteboard.active_tools_changed.connect(func(): tools = whiteboard.active_tools)


func _update_inspector() -> void:
	if inner_container:
		inner_container.queue_free()
	inner_container = VBoxContainer.new()
	inner_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(inner_container)
	for tool in tools:
		var properties := tool.get_property_list().filter(func(el): return el.usage & PROPERTY_USAGE_EDITOR and el.name != "script")
		if not properties:
			continue
		var header := Label.new()
		header.text = ReverseDNSUtil.pretty_print(tool.get_script().get_id()).trim_suffix("Tool").strip_edges()
		header.theme_type_variation = "HeaderMedium"
		inner_container.add_child(header)
		var outer_prop_container := MarginContainer.new()
		inner_container.add_child(outer_prop_container)
		var prop_container := VBoxContainer.new()
		outer_prop_container.add_child(prop_container)
		for property: Dictionary in properties:
			var label := Label.new()
			label.text = Util.pretty_print_property(property.name)
			prop_container.add_child(label)
			var delegate: Control = create_delegate(
				property, tool.get(property.name),
				func(new_value): tool.set(property.name, convert(new_value, property.type))
			)
			delegate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			prop_container.add_child(delegate)


static func create_delegate(prop: Dictionary, initial_value, set_prop: Callable) -> Control:
	return hint_delegates[prop.hint].call(prop, initial_value, set_prop)
