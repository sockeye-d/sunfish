extends WhiteboardTool


var current_image: Image
var image_preview_element: ImagePreviewElement


static func get_id() -> String: return "dev.fishies.sunfish.ImageTool"


func receive_input(wb: Whiteboard, event: InputEvent) -> Display:
	var display := WhiteboardTool.Display.new()
	if event.is_action_pressed("ui_paste"):
		var img := DisplayServer.clipboard_get_image()
		if img:
			current_image = img
			image_preview_element = ImagePreviewElement.new()
			image_preview_element.image = current_image
	var mm := event as InputEventMouseMotion
	if mm:
		if current_image:
			image_preview_element.center_position = mm.position
			wb.redraw_all()
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and current_image:
			var image_element := ImageElement.new()
			image_element.image = current_image
			image_element.rect = ImagePreviewElement.get_rect(current_image, mb.position, wb.draw_scale)
			display.elements = [image_element]
			image_preview_element = null
	if image_preview_element:
		display.preview_elements = [image_preview_element]
	return null


class ImagePreviewElement extends WhiteboardTool.PreviewElement:
	var image: Image:
		set(value):
			image = value
			image_texture = ImageTexture.create_from_image(value)
	var image_texture: ImageTexture
	var center_position: Vector2
	
	func draw(control: Control, wb: Whiteboard):
		var rect := get_rect(image, center_position, wb.draw_scale)
		control.draw_texture_rect(image_texture, rect, false)
	
	static func get_rect(_image: Image, _center_position: Vector2, draw_scale: float) -> Rect2:
		var rect := Rect2(0, 0, _image.get_width() / draw_scale, _image.get_height() / draw_scale)
		rect.position = _center_position - rect.size * 0.5
		return rect


class ImageElement extends WhiteboardTool.Element:
	var rect: Rect2
	var image: Image:
		set(value):
			image = value
			image_texture = ImageTexture.create_from_image(value)
	var image_texture: ImageTexture
	
	static func get_id() -> String: return "dev.fishies.sunfish.ImageTool"
	
	func draw(wb: Whiteboard):
		#image_texture.draw_rect(wb.get_canvas_item(), )
		wb.draw_texture_rect(image_texture, rect, false)
	
	func get_bounding_box() -> Rect2:
		return rect
