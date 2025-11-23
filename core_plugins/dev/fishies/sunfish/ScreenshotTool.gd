extends WhiteboardTool


const PROPERTY_HINT_EXT_TAKE_SCREENSHOT_BUTTON = 3369335536


const ScreenshotTool = preload("ScreenshotTool.gd")
const COMPOSITE_SCREENSHOT_SHADER := preload("composite_screenshot.glsl")


enum SelectionSide {
	NONE,
	INNER,
	LEFT,
	TOP_LEFT,
	TOP,
	TOP_RIGHT,
	RIGHT,
	BOTTOM_RIGHT,
	BOTTOM,
	BOTTOM_LEFT,
}


static func _static_init() -> void:
	Inspector.register_delegate(PROPERTY_HINT_EXT_TAKE_SCREENSHOT_BUTTON, func(prop: Dictionary, initial_value, set_prop: Callable) -> Inspector.Delegate:
		Util.unused(prop)
		var container := HBoxContainer.new()
		var screenshot_button := Button.new()
		screenshot_button.text = "Capture"
		screenshot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		screenshot_button.pressed.connect(Crimes.instance.take_screenshot.emit)
		container.add_child(screenshot_button)
		var to_clipboard_button := Button.new()
		to_clipboard_button.icon = IconTexture2D.create("clipboard")
		to_clipboard_button.toggle_mode = true
		to_clipboard_button.toggled.connect(func(mode):
			set_prop.call(mode)
		)
		to_clipboard_button.button_pressed = initial_value
		set_prop.call(initial_value)
		container.add_child(to_clipboard_button)
		return Inspector.Delegate.new(container)
	)


static func get_id() -> StringName: return "dev.fishies.sunfish.ScreenshotTool"


static func get_shortcut() -> InputEvent: return Shortcuts.key(KEY_S)


var start_pos: Vector2
var preview := ScreenshotPreviewElement.new()
var dragging_side: SelectionSide
var whiteboard: Whiteboard


@export_custom(
	PROPERTY_HINT_EXT_TAKE_SCREENSHOT_BUTTON, "",
	PROPERTY_USAGE_DEFAULT | Inspector.PROPERTY_USAGE_EXT_NO_LABEL
) var take_screenshot: bool = true


@export_range(500.0, 5000.0, 1.0, "or_greater") var resolution: float = 1000.0:
	set(value):
		resolution = value
		_recalculate_resolution()
var screenshot_rect: Rect2:
	set(value):
		screenshot_rect = value
		abs_screenshot_rect = screenshot_rect.abs()
		_recalculate_resolution()
var abs_screenshot_rect: Rect2
var scaling_factor: float
var pixel_resolution: Vector2


@export_custom(
	PROPERTY_HINT_EXT_CUSTOM_INSPECTOR, "_create_resolution_widget",
	PROPERTY_USAGE_DEFAULT | Inspector.PROPERTY_USAGE_EXT_NO_LABEL
) var resolution_widget


var label: Label
func _create_resolution_widget() -> Control:
	label = Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recalculate_resolution()
	return label


func _init() -> void:
	Crimes.instance.take_screenshot.connect(func(): _render_screenshot(take_screenshot))


func _recalculate_resolution() -> void:
	var axis := abs_screenshot_rect.size.max_axis_index()
	scaling_factor = resolution / abs_screenshot_rect.size[axis]
	pixel_resolution = abs_screenshot_rect.size * scaling_factor
	if label:
		if not pixel_resolution.is_finite() or is_nan(pixel_resolution.x) or is_nan(pixel_resolution.y):
			label.hide()
		else:
			label.show()
			label.text = "%.f×%.f" % [pixel_resolution.x, pixel_resolution.y]


var rd: RenderingDevice
var shader: RID


func _render_screenshot(copy: bool) -> void:
	var rect := abs_screenshot_rect
	if rect.size == Vector2.ZERO:
		return
	var vp := SubViewport.new()
	@warning_ignore("unused_variable")
	var vp_queue_free_defer := Defer.new(vp.queue_free)
	TreeEvents.add_child(vp)
	vp.transparent_bg = true
	vp.msaa_2d = Viewport.MSAA_8X
	vp.size = pixel_resolution
	vp.canvas_transform = Transform2D(0.0, -rect.position).scaled(Vector2.ONE * scaling_factor)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	for el_index in whiteboard.elements.size():
		var layer := Whiteboard.ElementLayer.new()
		layer.whiteboard = whiteboard
		layer.index = el_index
		vp.add_child(layer)
		layer.queue_redraw()
	await RenderingServer.frame_post_draw
	var vp_tex := vp.get_texture()
	var vp_image := vp_tex.get_image()
	if vp_image == null:
		ToastManager.push_toast(
			ToastManager.Severity.ERROR,
			"Failed to capture screenshot"
		)
		return

	if not rd:
		rd = RenderingServer.create_local_rendering_device()
		shader = rd.shader_create_from_spirv(COMPOSITE_SCREENSHOT_SHADER.get_spirv())

	var viewport_format := RDTextureFormat.new()
	viewport_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	viewport_format.width = vp.size.x
	viewport_format.height = vp.size.y
	viewport_format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT

	var output_format := RDTextureFormat.new()
	output_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	output_format.width = vp.size.x
	output_format.height = vp.size.y
	output_format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT

	var output_rid := rd.texture_create(output_format, RDTextureView.new())
	@warning_ignore("unused_variable")
	var output_rid_defer := Defer.new(rd.free_rid.bind(output_rid))

	var viewport_uniform := RDUniform.new()
	viewport_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	viewport_uniform.binding = 0
	var viewport_image := rd.texture_create(viewport_format, RDTextureView.new(), [vp_image.get_data()])
	viewport_uniform.add_id(viewport_image)
	@warning_ignore("unused_variable")
	var viewport_image_defer := Defer.new(rd.free_rid.bind(viewport_image))

	var output_uniform := RDUniform.new()
	output_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_uniform.binding = 1
	output_uniform.add_id(output_rid)

	var bg_color := ThemeManager.active_theme.background_0
	var bg_color_bytes := PackedFloat32Array([bg_color.r, bg_color.g, bg_color.b, 0.0]).to_byte_array()

	var bg_color_buffer := rd.uniform_buffer_create(bg_color_bytes.size(), bg_color_bytes)
	@warning_ignore("unused_variable")
	var bg_color_buffer_defer := Defer.new(rd.free_rid.bind(bg_color_buffer))

	var bg_color_uniform := RDUniform.new()
	bg_color_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	bg_color_uniform.binding = 2
	bg_color_uniform.add_id(bg_color_buffer)

	var pipeline := rd.compute_pipeline_create(shader)
	@warning_ignore("unused_variable")
	var pipeline_defer := Defer.new(rd.free_rid.bind(pipeline))
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	var uniform_set := rd.uniform_set_create([viewport_uniform, output_uniform, bg_color_uniform], shader, 0)
	@warning_ignore("unused_variable")
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, vp.size.x, vp.size.y, 1)
	rd.compute_list_end()

	rd.submit()
	rd.sync()

	var data := rd.texture_get_data(output_rid, 0)
	if data.is_empty():
		ToastManager.push_toast(
			ToastManager.Severity.ERROR,
			"Failed to retrieve data from GPU"
		)
		return
	var image := Image.create_from_data(vp.size.x, vp.size.y, false, Image.FORMAT_RGBA8, data)
	if image == null:
		ToastManager.push_toast(
			ToastManager.Severity.ERROR,
			"Failed to create image from data"
		)
		return

	if copy:
		var image_data := ClipboardUtils.ImageExportData.new()
		image_data.format = "png"
		image_data.image = image
		var status := ClipboardUtils.copy_image(image_data)
		if status.type != ClipboardUtils.ErrorType.Ok:
			printerr(status.message)
			ToastManager.push_toast(
				ToastManager.Severity.ERROR,
				"Failed to copy: " + status.message,
			)
		else:
			ToastManager.push_toast(
				ToastManager.Severity.SUCCESS,
				"Copied to clipboard",
			)
		return
	var path: PackedStringArray = await DialogUtil.open_file_dialog(["*.png;Images;image/png"], FileDialog.FILE_MODE_SAVE_FILE, "~")
	if path:
		var err := image.save_png(path[0])
		if err:
			ToastManager.push_toast(
				ToastManager.Severity.ERROR,
				"Failed: " + error_string(err),
			)
		else:
			var button := Button.new()
			button.text = "Show folder"
			button.pressed.connect(OS.shell_show_in_file_manager.bind(path[0]))
			ToastManager.push_toast(
				ToastManager.Severity.SUCCESS,
				"Saved image",
				[button]
			)


func activated(wb: Whiteboard) -> void:
	whiteboard = wb
	if preview:
		wb.redraw_preview([], [preview])


func should_hide_mouse() -> bool: return false


func receive_input(wb: Whiteboard, event: InputEvent) -> Display:
	Util.unused(wb)
	var display := Display.new([], [], [preview])
	var handle_size := 8.0 / wb.draw_scale
	display.cursor_shape = Control.CURSOR_ARROW
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if screenshot_rect.grow(-handle_size).abs().has_point(mb.position):
					dragging_side = SelectionSide.INNER
				else:
					var closest_side: Array[SelectionSide]
					if get_closest_side(mb.position, screenshot_rect, closest_side) < handle_size:
						dragging_side = closest_side[0]
					else:
						screenshot_rect = Rect2(mb.position, Vector2.ONE)
						dragging_side = SelectionSide.NONE
				display.cursor_shape = get_cursor_shape(dragging_side, true)
			else:
				dragging_side = SelectionSide.NONE
				screenshot_rect = screenshot_rect.abs()
		if screenshot_rect.grow(-handle_size).abs().has_point(mb.position):
			display.cursor_shape = get_cursor_shape(SelectionSide.INNER, false)
	var mm := event as InputEventMouseMotion
	if mm:
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if dragging_side != SelectionSide.NONE:
				screenshot_rect = grow_rect(screenshot_rect, dragging_side, mm.relative)
			else:
				screenshot_rect.size = mm.position - screenshot_rect.position
		if dragging_side != SelectionSide.NONE:
			display.cursor_shape = get_cursor_shape(dragging_side, mm.button_mask & MOUSE_BUTTON_MASK_LEFT)
		else:
			if screenshot_rect.grow(-handle_size).abs().has_point(mm.position):
				display.cursor_shape = get_cursor_shape(SelectionSide.INNER, false)
			else:
				var closest_side: Array[SelectionSide]
				if get_closest_side(mm.position, screenshot_rect, closest_side) < handle_size:
					display.cursor_shape = get_cursor_shape(closest_side[0], mm.button_mask & MOUSE_BUTTON_MASK_LEFT)
	preview.rect = screenshot_rect
	if event.is_match(Settings["dev.fishies.sunfish.ScreenshotTool.ScreenshotTool/capture_screenshot"]) and event.is_pressed():
		_render_screenshot(take_screenshot)
	if event.is_match(Settings["dev.fishies.sunfish.ScreenshotTool.ScreenshotTool/copy_screenshot"]) and event.is_pressed():
		_render_screenshot(true)
	return display


static func get_side_rect_pos(rect: Rect2, side: SelectionSide) -> Vector2:
	match side:
		SelectionSide.LEFT:
			return Vector2(rect.position.x, rect.position.y + rect.size.y * 0.5)
		SelectionSide.TOP_LEFT:
			return Vector2(rect.position.x, rect.position.y)
		SelectionSide.TOP:
			return Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y)
		SelectionSide.TOP_RIGHT:
			return Vector2(rect.position.x + rect.size.x, rect.position.y)
		SelectionSide.RIGHT:
			return Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y * 0.5)
		SelectionSide.BOTTOM_RIGHT:
			return Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y)
		SelectionSide.BOTTOM:
			return Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y)
		SelectionSide.BOTTOM_LEFT:
			return Vector2(rect.position.x, rect.position.y + rect.size.y)
	return Vector2()


static func grow_rect(rect: Rect2, side: SelectionSide, delta: Vector2) -> Rect2:
	match side:
		SelectionSide.INNER:
			return Rect2(rect.position + delta, rect.size)
		SelectionSide.LEFT:
			return rect.grow_side(SIDE_LEFT, -delta.x)
		SelectionSide.TOP_LEFT:
			return rect.grow_side(SIDE_LEFT, -delta.x).grow_side(SIDE_TOP, -delta.y)
		SelectionSide.TOP:
			return rect.grow_side(SIDE_TOP, -delta.y)
		SelectionSide.TOP_RIGHT:
			return rect.grow_side(SIDE_RIGHT, delta.x).grow_side(SIDE_TOP, -delta.y)
		SelectionSide.RIGHT:
			return rect.grow_side(SIDE_RIGHT, delta.x)
		SelectionSide.BOTTOM_RIGHT:
			return rect.grow_side(SIDE_RIGHT, delta.x).grow_side(SIDE_BOTTOM, delta.y)
		SelectionSide.BOTTOM:
			return rect.grow_side(SIDE_BOTTOM, delta.y)
		SelectionSide.BOTTOM_LEFT:
			return rect.grow_side(SIDE_LEFT, -delta.x).grow_side(SIDE_BOTTOM, delta.y)
	return Rect2()


static func get_cursor_shape(side: SelectionSide, mb_pressed: bool) -> Control.CursorShape:
	match side:
		SelectionSide.INNER: return Control.CURSOR_CAN_DROP if mb_pressed else Control.CURSOR_DRAG
		SelectionSide.LEFT: return Control.CURSOR_HSIZE
		SelectionSide.TOP_LEFT: return Control.CURSOR_FDIAGSIZE
		SelectionSide.TOP: return Control.CURSOR_VSIZE
		SelectionSide.TOP_RIGHT: return Control.CURSOR_BDIAGSIZE
		SelectionSide.RIGHT: return Control.CURSOR_HSIZE
		SelectionSide.BOTTOM_RIGHT: return Control.CURSOR_FDIAGSIZE
		SelectionSide.BOTTOM: return Control.CURSOR_VSIZE
		SelectionSide.BOTTOM_LEFT: return Control.CURSOR_BDIAGSIZE
	return Control.CURSOR_ARROW


static func get_closest_side(mouse_pos: Vector2, rect: Rect2, out_side: Array[SelectionSide]) -> float:
	var closest_side: SelectionSide
	var closest_side_distance: float = INF
	for side in range(SelectionSide.LEFT, SelectionSide.size()):
		var side_pos := get_side_rect_pos(rect, side as SelectionSide)
		var distance := side_pos.distance_to(mouse_pos)
		if distance < closest_side_distance:
			closest_side_distance = distance
			closest_side = side as SelectionSide
	out_side.append(closest_side)
	return closest_side_distance


class ScreenshotPreviewElement extends StaticPreviewElement:
	var rect: Rect2
	func draw(wb: Whiteboard) -> void:
		const ARC_LENGTHS: PackedVector2Array = [
			Vector2(PI * 0.5, PI * 1.5),
			Vector2(PI * 0.5, TAU),
			Vector2(0.0, -PI),
			Vector2(-PI, PI * 0.5),
			Vector2(-PI * 0.5, PI * 0.5),
			Vector2(-PI * 0.5, PI),
			Vector2(0.0, PI),
			Vector2(0.0, PI * 1.5),
		]
		var xformed_rect := wb.draw_xform * rect
		wb.draw_rect(xformed_rect, ThemeManager.active_theme.accent_0, false, 2.0)
		for side in range(SelectionSide.LEFT, SelectionSide.size()):
			var arc_length := ARC_LENGTHS[side - 2]
			wb.draw_arc(
				ScreenshotTool.get_side_rect_pos(xformed_rect, side as SelectionSide),
				8.0,
				arc_length.x, arc_length.y, 16,
				ThemeManager.active_theme.accent_0, 0.9, true
			)


class ScreenshotToolShortcuts extends Configuration:
	static func _static_init() -> void:
		PluginManager.register_configuration(new())

	func get_id() -> StringName: return "dev.fishies.sunfish.ScreenshotTool.ScreenshotTool"

	@export var capture_screenshot := Shortcuts.key(KEY_S | KEY_MASK_SHIFT)
	@export var copy_screenshot := Shortcuts.key(KEY_C | KEY_MASK_CTRL)


class Crimes:
	static var instance: Crimes:
		get:
			if not instance:
				instance = Crimes.new()
			return instance
	signal take_screenshot
