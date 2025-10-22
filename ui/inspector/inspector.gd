class_name Inspector extends PanelContainer

enum {
	PROPERTY_HINT_EXT_PRETTY_RDNS_ENUM = 256,
}

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
		slider.step = maxf(step, 0.01)
		slider.min_value = min_value
		slider.max_value = max_value
		slider.allow_greater = "or_greater" in extra_hints
		slider.allow_lesser = "or_less" in extra_hints
		slider.slider_value = initial_value
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
				var event_btn := EventInput.new(initial_value)
				event_btn.event_submitted.connect(func(event: InputEvent): set_prop.call(event))
				return event_btn
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


var tool_properties: Dictionary[StringName, Dictionary]
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
	var existing_tool_properties: Dictionary[StringName, Dictionary] = Settings.get_safe("state/tool_properties").front()
	if existing_tool_properties == null:
		existing_tool_properties = {}
	for tool in tools:
		var properties := tool.get_property_list().filter(func(el): return el.usage & PROPERTY_USAGE_EDITOR and el.name != "script")
		if not properties:
			continue
		var property_dict: Dictionary[StringName, Variant]
		var tool_id: String = tool.get_script().get_id()
		var single_tool_properties = existing_tool_properties.get(tool_id, {})
		var header := Label.new()
		header.text = ReverseDNSUtil.pretty_print(tool_id).trim_suffix("Tool").strip_edges()
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
			var property_value = single_tool_properties[property.name] if property.name in single_tool_properties else tool.get(property.name)
			property_dict[property.name] = property_value
			var delegate: Control = create_delegate(
				property, property_value,
				func(new_value):
					new_value = type_convert(new_value, property.type)
					property_dict[property.name] = new_value
					tool.set(property.name, new_value)
					Settings["state/tool_properties"] = tool_properties
			)
			delegate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			prop_container.add_child(delegate)
		tool_properties[tool_id] = property_dict
	Settings["state/tool_properties"] = tool_properties


static func create_delegate(prop: Dictionary, initial_value, set_prop: Callable) -> Control:
	return hint_delegates[prop.hint].call(prop, initial_value, set_prop)
