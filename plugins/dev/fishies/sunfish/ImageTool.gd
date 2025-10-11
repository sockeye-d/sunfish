extends WhiteboardTool


var current_image: Image
var image_preview_element: ImagePreviewElement


static func get_id() -> String: return "dev.fishies.sunfish.ImageTool"


func activated(wb: Whiteboard) -> void:
	var img := DisplayServer.clipboard_get_image()
	if img and not img.is_empty():
		current_image = img
		image_preview_element = ImagePreviewElement.new()
		image_preview_element.image = current_image
		wb.redraw_all()


func receive_input(wb: Whiteboard, event: InputEvent) -> Display:
	var display := WhiteboardTool.Display.new()
	if event.is_action_pressed("ui_paste"):
		var img := DisplayServer.clipboard_get_image()
		if img and not img.is_empty():
			current_image = img
			image_preview_element = ImagePreviewElement.new()
			image_preview_element.image = current_image
			image_preview_element.center_position = wb.draw_xform * wb.get_local_mouse_position()
	if event.is_action_pressed("ui_cancel"):
		current_image = null
		image_preview_element = null
		wb.redraw_all()
	var mm := event as InputEventMouseMotion
	if mm:
		if current_image and image_preview_element:
			image_preview_element.center_position = mm.position
			wb.redraw_all()
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if current_image:
				var image_element := ImageElement.new()
				image_element.image = current_image
				image_element.rect = ImagePreviewElement.get_rect(current_image, mb.position, wb.draw_scale)
				display.elements = [image_element]
				image_preview_element = null
				current_image = null
				wb.redraw_all()
			else:
				var img_path: PackedStringArray = await FileDialogUtil.open_file_dialog([], FileDialog.FILE_MODE_OPEN_FILE).selected
				if img_path:
					var img := Image.new()
					var err := img.load(img_path[0])
					if err:
						print("%s when loading file %s" % [error_string(err), img_path[0]])
					else:
						current_image = img
						image_preview_element = ImagePreviewElement.new()
						image_preview_element.image = current_image
						image_preview_element.center_position = wb.draw_xform * wb.get_local_mouse_position()
	if image_preview_element:
		display.preview_elements = [image_preview_element]
	return display


class ImagePreviewElement extends WhiteboardTool.PreviewElement:
	var image: Image:
		set(value):
			image = value
			image_texture = ImageTexture.create_from_image(value)
	var image_texture: ImageTexture
	var center_position: Vector2
	
	func draw(control: Control, wb: Whiteboard):
		var rect := get_rect(image, center_position, wb.draw_scale)
		control.draw_texture_rect(image_texture, rect, false, Color(1.0, 1.0, 1.0, 0.5))
	
	static func get_rect(_image: Image, _center_position: Vector2, draw_scale: float) -> Rect2:
		var rect := Rect2(0, 0, _image.get_width() / draw_scale, _image.get_height() / draw_scale)
		rect.position = _center_position - rect.size * 0.5
		return rect


class ImageElement extends WhiteboardTool.Element:
	static func _static_init() -> void:
		WhiteboardTools.register_deserializer(ImageElement)
	
	var rect: Rect2
	var image: Image:
		set(value):
			image = value
			image_texture = ImageTexture.create_from_image(value)
	var image_texture: ImageTexture
	
	static func get_id() -> String: return "dev.fishies.sunfish.ImageTool"
	
	func draw(wb: Whiteboard):
		wb.draw_texture_rect(image_texture, rect, false)
	
	func get_bounding_box() -> Rect2:
		return rect
	
	
	func serialize() -> Dictionary:
		var image_data := image.get_data()
		var image_data_compressed := image_data.compress(FileAccess.COMPRESSION_ZSTD)
		return {
			"rect": rect,
			"image_data_length": image_data.size(),
			"image_data": image_data_compressed,
			"image_width": image.get_width(),
			"image_height": image.get_height(),
			"image_format": image.get_format(),
		}
	
	
	static func deserialize(data: Dictionary) -> Element:
		var el := ImageElement.new()
		el.rect = data.rect
		var image_data = data.image_data.decompress(data.image_data_length, FileAccess.COMPRESSION_ZSTD)
		var new_image := Image.create_from_data(data.image_width, data.image_height, false, data.image_format, image_data)
		#var new_image := Image.new()
		#new_image.load_png_from_buffer(data.image_data)
		el.image = new_image
		return el
