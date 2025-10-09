@tool
class_name Whiteboard extends Panel

const BrushTool = preload("uid://c1ms438i3s12n")
const PanTool = preload("uid://ios48ehu0i7f")

var mouse_last_pos: Vector2
var is_drawing: bool
var draw_xform: Transform2D:
	set(value):
		draw_xform = value
		inv_draw_xform = draw_xform.affine_inverse()
		draw_scale = draw_xform.get_scale().length() / sqrt(2.0)
var inv_draw_xform: Transform2D
var draw_scale: float
var elements: Array[WhiteboardTool.Element]
var preview_elements: Array[WhiteboardTool.PreviewElement]
var active_tools: Array[WhiteboardTool] = [PanTool.new(), BrushTool.new()]

@export var color_picker: NiceColorPicker

var primary_color: Color

var preview: PreviewControl


func _init() -> void:
	clip_contents = true
	preview = PreviewControl.new()
	preview.wb = self
	add_child(preview)
	draw_xform = Transform2D.IDENTITY


func _ready() -> void:
	if color_picker:
		color_picker.color_changed.connect(func(new_color: Color): primary_color = new_color)
		primary_color = color_picker.color


func _draw() -> void:
	draw_set_transform_matrix(draw_xform)
	# TODO: culling
	var self_bounds = (inv_draw_xform * Rect2(Vector2.ZERO, size)).abs()
	var draw_scale_cache := draw_scale
	for element in elements:
		var bounds := element.get_bounding_box()
		var screen_size := bounds.size[bounds.size.max_axis_index()] * draw_scale_cache
		if screen_size > 2.0 and self_bounds.intersects(bounds):
			element.draw(self)


func redraw_all() -> void:
	queue_redraw()
	preview.queue_redraw()


func _gui_input(e: InputEvent) -> void:
	var new_preview_elements: Array[WhiteboardTool.PreviewElement]
	for tool in active_tools:
		var tool_output := tool.receive_input(self, e.xformed_by((draw_xform).affine_inverse()))
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


class PreviewControl extends Control:
	var wb: Whiteboard
	
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
	
	func _draw() -> void:
		draw_set_transform_matrix(wb.draw_xform)
		for preview_element in wb.preview_elements:
			preview_element.draw(self, wb)
