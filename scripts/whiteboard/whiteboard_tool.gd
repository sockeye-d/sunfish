@abstract
class_name WhiteboardTool


## Get a reverse-DNS (e.g. com.example.Tool) identifier specific to this tool
static func get_id() -> String:
	assert(false)
	return ""


@abstract
func receive_input(wb: Whiteboard, event: InputEvent) -> Display


func create_configuration_display() -> Control: return null


func activated(wb: Whiteboard) -> void: Util.unused(wb)


func should_hide_mouse() -> bool: return false


static func is_visible() -> bool: return true


@abstract
class Element:
	## Get a reverse-DNS (e.g. com.example.Tool) identifier specific to this tool
	static func get_id() -> String:
		assert(false)
		return ""
	
	
	@abstract
	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void
	
	
	@abstract
	func get_bounding_box() -> Rect2
	
	
	func dragged(delta: Vector2) -> void:
		Util.unused(delta)
	
	
	@abstract
	func serialize() -> Dictionary
	
	
	static func deserialize(data: Dictionary) -> Element:
		Util.unused(data)
		assert(false)
		return null


@abstract
class PreviewElement:
	@abstract
	func draw(canvas: CanvasItem, wb: Whiteboard)


class PlainPreviewElement extends WhiteboardTool.PreviewElement:
	var position: Vector2
	var color: Color
	var width: float
	
	func draw(canvas: CanvasItem, _wb: Whiteboard):
		canvas.draw_circle(position, width * 0.5, color, false, -2.0, false)


class Display:
	var elements: Array[Element]
	var preview_elements: Array[PreviewElement]
	
	func _init(_elements: Array[Element] = [], _preview_elements: Array[PreviewElement] = []) -> void:
		elements = _elements
		preview_elements = _preview_elements
