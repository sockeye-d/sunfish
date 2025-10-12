@tool
class_name Whiteboard extends Control

const PanTool = preload("uid://ios48ehu0i7f")
const WHITEBOARD_BACKGROUND = preload("uid://h1qiidxtgcs0")

signal xform_changed
signal active_tools_changed

signal element_count_changed

var mouse_last_pos: Vector2
var is_drawing: bool

var draw_xform: Transform2D:
	set(value):
		draw_xform = value
		inv_draw_xform = draw_xform.affine_inverse()
		draw_scale = draw_xform.get_scale().length() / sqrt(2.0)
		draw_origin = draw_xform.get_origin()
		xform_changed.emit()
		redraw_all()
var inv_draw_xform: Transform2D
var draw_scale: float
var draw_origin: Vector2

var elements: Array[WhiteboardTool.Element]
var preview_elements: Array[WhiteboardTool.PreviewElement]
var active_tools: Array[WhiteboardTool] = [PanTool.new()]

var active_element_count: int
var visible_element_count: int

@export var color_picker: NiceColorPicker

var primary_color: Color

var background: Panel
var background_shader: ColorRect
var preview: PreviewControl


func _init() -> void:
	clip_contents = true
	draw_xform = Transform2D.IDENTITY
	background = Panel.new()
	background.show_behind_parent = true
	background.clip_contents = true
	#background.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	background.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	var mat := ShaderMaterial.new()
	mat.shader = WHITEBOARD_BACKGROUND
	
	background_shader = ColorRect.new()
	background_shader.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_shader.material = mat
	background_shader.show_behind_parent = true
	background.add_child(background_shader)
	
	preview = PreviewControl.new()
	preview.wb = self
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview)
	
	xform_changed.connect(func():
		var x := Vector3(inv_draw_xform[0][0], inv_draw_xform[0][1], 0.0)
		var y := Vector3(inv_draw_xform[1][0], inv_draw_xform[1][1], 0.0)
		var z := Vector3(inv_draw_xform[2][0], inv_draw_xform[2][1], 0.0)
		mat.set_shader_parameter("xform", Basis(x, y, z))
	)
	
	focus_mode = Control.FOCUS_ALL


func _ready() -> void:
	if color_picker:
		color_picker.color_changed.connect(func(new_color: Color): primary_color = new_color)
		primary_color = color_picker.color
	var fd := FileAccess.open("user://save.sunfish", FileAccess.READ)
	if fd:
		var json_size := fd.get_64()
		var json_compressed := fd.get_buffer(FileAccess.get_size("user://save.sunfish") - fd.get_position())
		elements = WhiteboardTools.deserialize(bytes_to_var(json_compressed.decompress(json_size, FileAccess.COMPRESSION_ZSTD)))


func _draw() -> void:
	#get_tree().root.msaa_2d = Viewport.MSAA_4X
	var new_element_count := elements.size()
	var new_visible_element_count := 0
	draw_set_transform_matrix(draw_xform)
	var self_bounds = (inv_draw_xform * Rect2(Vector2.ZERO, size)).abs()
	var draw_scale_cache := draw_scale
	for element in elements:
		var bounds := element.get_bounding_box()
		var screen_size := bounds.size[bounds.size.max_axis_index()] * draw_scale_cache
		if DebugManager.show_bounds:
			draw_rect(bounds, Color.RED, false, 2.0 / draw_scale_cache)
		if screen_size > 2.0 and self_bounds.intersects(bounds):
			new_visible_element_count += 1
			element.draw(self)
	
	if new_visible_element_count != visible_element_count or new_element_count != active_element_count:
		active_element_count = elements.size()
		visible_element_count = new_visible_element_count
		element_count_changed.emit()


func _gui_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_undo", true):
		undo()
	if e.is_action_pressed("save"):
		var json := var_to_bytes(WhiteboardTools.serialize(elements))
		var json_compressed := json.compress(FileAccess.COMPRESSION_ZSTD)
		var fd := FileAccess.open("user://save.sunfish", FileAccess.WRITE)
		fd.store_64(json.size())
		fd.store_buffer(json_compressed)
		print(json_compressed.size())
		elements = WhiteboardTools.deserialize(bytes_to_var(json_compressed.decompress(json.size(), FileAccess.COMPRESSION_ZSTD)))
		queue_redraw()
	if e is InputEventMouseMotion and not has_focus():
		grab_focus()
	var new_preview_elements: Array[WhiteboardTool.PreviewElement]
	for tool in active_tools:
		@warning_ignore("redundant_await") # I don't know why it thinks this isn't a coroutine
		var tool_output := await tool.receive_input(self, e.xformed_by((draw_xform).affine_inverse()))
		if tool_output == null:
			continue
		
		if not tool_output.elements.is_empty():
			if elements.slice(elements.size() - tool_output.elements.size()) != tool_output.elements:
				elements.append_array(tool_output.elements)
			queue_redraw()
		
		if not tool_output.preview_elements.is_empty():
			new_preview_elements.append_array(tool_output.preview_elements)
	
	preview_elements = new_preview_elements
	if not preview_elements.is_empty():
		preview.queue_redraw()


func undo() -> void:
	elements.pop_back()
	queue_redraw()


func redraw_all() -> void:
	queue_redraw()
	if preview:
		preview.queue_redraw()


func set_active_tools(new_active_tools: Array[WhiteboardTool]) -> void:
	var new_tools: Array[WhiteboardTool]
	for tool in active_tools:
		if not tool.get_script().is_visible():
			new_tools.append(tool)
	new_tools.append_array(new_active_tools)
	for tool in new_active_tools:
		tool.activated(self)
	active_tools = new_tools
	active_tools_changed.emit()


class PreviewControl extends Control:
	var wb: Whiteboard
	
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
	
	func _draw() -> void:
		draw_set_transform_matrix(wb.draw_xform)
		for preview_element in wb.preview_elements:
			preview_element.draw(self, wb)
