@abstract
class_name WhiteboardTool

@abstract
func receive_input(wb: Whiteboard, event: InputEvent) -> Display

@abstract
class Element:
	@abstract
	func draw(wb: Whiteboard)
	
	@abstract
	func get_bounding_box() -> Rect2


@abstract
class PreviewElement:
	@abstract
	func draw(control: Control, wb: Whiteboard)


class Display:
	var elements: Array[Element]
	var preview_elements: Array[PreviewElement]
	
	func _init(_elements: Array[Element] = [], _preview_elements: Array[PreviewElement] = []) -> void:
		elements = _elements
		preview_elements = _preview_elements
