@tool
class_name Whiteboard extends Panel

const BrushTool = preload("uid://c1ms438i3s12n")
const PanTool = preload("uid://ios48ehu0i7f")

var mouse_last_pos: Vector2
var is_drawing: bool
var draw_xform: Transform2D
var draw_scale: float:
	set(_v): assert(false)
	get: return draw_xform.get_scale().length() / sqrt(2.0)
var elements: Array[WhiteboardTool.Element]
var preview_elements: Array[WhiteboardTool.PreviewElement]
var active_tools: Array[WhiteboardTool] = [PanTool.new(), BrushTool.new()]

var preview: PreviewControl


func _init() -> void:
	clip_contents = true
	preview = PreviewControl.new()
	preview.wb = self
	add_child(preview)


func _draw() -> void:
	draw_set_transform_matrix(draw_xform)
	# TODO: culling
	#var self_bounds = Rect2(Vector2.ZERO, size).grow(-100) * draw_xform
	for element in elements:
		#var bounds := element.get_bounding_box()
		#if self_bounds.abs().intersects(bounds):
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
