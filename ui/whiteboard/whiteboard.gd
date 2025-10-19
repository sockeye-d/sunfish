@tool
class_name Whiteboard extends Control

const OVERSAMPLE = 1.0
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
		if viewport:
			viewport.canvas_transform = draw_xform * OVERSAMPLE
		redraw_preview()
var inv_draw_xform: Transform2D
var draw_scale: float
var draw_origin: Vector2

var elements: Array[WhiteboardTool.Element]
var preview_elements: Array[WhiteboardTool.PreviewElement]
var active_tools: Array[WhiteboardTool] = []

var active_element_count: int:
	get: return elements.size()

@export var color_picker: NiceColorPicker

var primary_color: Color

var background: Panel
var background_shader: ColorRect
var preview: PreviewControl


var viewport_container: Control
var viewport: Viewport
var layer_container: Node2D


var save_timer: Timer


func _init() -> void:
	save_timer = Timer.new()
	save_timer.wait_time = 0.5
	save_timer.one_shot = true
	add_child(save_timer)
	
	clip_contents = true
	draw_xform = Transform2D.IDENTITY
	background = Panel.new()
	background.show_behind_parent = true
	background.clip_contents = true
	background.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	var mat := ShaderMaterial.new()
	mat.shader = WHITEBOARD_BACKGROUND
	
	background_shader = ColorRect.new()
	background_shader.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_shader.material = mat
	background.add_child(background_shader)
	
	xform_changed.connect(func():
		var x := Vector3(inv_draw_xform[0][0], inv_draw_xform[0][1], 0.0)
		var y := Vector3(inv_draw_xform[1][0], inv_draw_xform[1][1], 0.0)
		var z := Vector3(inv_draw_xform[2][0], inv_draw_xform[2][1], 0.0)
		mat.set_shader_parameter("xform", Basis(x, y, z))
	)
	
	focus_mode = Control.FOCUS_ALL
	
	theme_changed.connect(func(): if ThemeManager.active_theme: mat.set_shader_parameter("text_color", ThemeManager.active_theme.text))
	
	mouse_entered.connect(func():
		if active_tools.any(func(e: WhiteboardTool): return e.should_hide_mouse()):
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	)
	mouse_exited.connect(func(): Input.mouse_mode = Input.MOUSE_MODE_VISIBLE)
	
	viewport_container = SubViewportContainer.new()
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport.msaa_2d = Viewport.MSAA_4X
	resized.connect(func(): viewport.size = size * OVERSAMPLE)
	var render_mat := ShaderMaterial.new()
	render_mat.shader = preload("whiteboard_render.gdshader")
	render_mat["shader_parameter/canvas_texture"] = viewport.get_texture()
	viewport_container.material = render_mat
	
	layer_container = Node2D.new()
	viewport_container.add_child(viewport)
	viewport.add_child(layer_container)
	
	preview = PreviewControl.new()
	preview.wb = self
	viewport.add_child(preview)
	
	add_child(viewport_container)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		serialize_or_new()


func _ready() -> void:
	if color_picker:
		color_picker.color_changed.connect(func(new_color: Color): primary_color = new_color)
		primary_color = color_picker.color
	if ThemeManager.active_theme:
		(func():
			background_shader.material.set_shader_parameter("text_color", ThemeManager.active_theme.text)
		).call_deferred()
	if Settings["state/last_opened_filepath"]:
		var peer := StreamPeerFile.open(Settings["state/last_opened_filepath"], FileAccess.READ)
		if peer:
			deserialize(peer)
		else:
			serialize_or_new()
	else:
		serialize_or_new()
	
	DataManager.file_save.connect(func(filepath: String):
		Util.unused(filepath)
		serialize()
	)
	
	DataManager.file_load.connect(func(filepath: String):
		deserialize(StreamPeerFile.open(filepath, FileAccess.READ))
	)
	
	DataManager.file_new.connect(func():
		reset()
		serialize_or_new()
	)
	
	save_timer.timeout.connect(serialize_or_new)


var _preview_draw_twice := false
func _gui_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_undo", true):
		undo()
	if e is InputEventMouseMotion and not has_focus():
		grab_focus()
	var new_preview_elements: Array[WhiteboardTool.PreviewElement]
	var tools: Array[WhiteboardTool]
	tools.append_array(WhiteboardManager.passive_tools.values())
	tools.append_array(active_tools)
	for tool in tools:
		@warning_ignore("redundant_await") # I don't know why it thinks this isn't a coroutine
		var tool_output := await tool.receive_input(self, e.xformed_by((draw_xform).affine_inverse()))
		if tool_output == null:
			continue
		
		if not tool_output.elements.is_empty():
			if elements.slice(elements.size() - tool_output.elements.size()) != tool_output.elements:
				var old_element_size := elements.size()
				elements.append_array(tool_output.elements)
				for element_index in range(old_element_size, elements.size()):
					layer_container.add_child(create_layer(element_index))
				element_count_changed.emit()
				save()
			else:
				for layer_index in range(elements.size() - tool_output.elements.size(), elements.size()):
					(layer_container.get_child(layer_index) as ElementLayer).queue_redraw()
				save()
		
		if not tool_output.preview_elements.is_empty():
			new_preview_elements.append_array(tool_output.preview_elements)
	
	preview_elements = new_preview_elements
	if not preview_elements.is_empty() or _preview_draw_twice:
		_preview_draw_twice = not preview_elements.is_empty()
		preview.queue_redraw()


func undo() -> void:
	elements.pop_back()
	layer_container.remove_child(layer_container.get_child(layer_container.get_child_count() - 1))
	save()
	queue_redraw()


func redraw_preview() -> void:
	if preview:
		preview.queue_redraw()


func set_active_tools(new_active_tools: Array[WhiteboardTool]) -> void:
	for tool in new_active_tools:
		tool.activated(self)
	active_tools = new_active_tools
	active_tools_changed.emit()


func save() -> void:
	save_timer.start()


func serialize_or_new() -> void:
	var filepath: String = Settings["state/last_opened_filepath"]
	if not filepath:
		filepath = DataManager.get_default_save_path()
		Settings["state/last_opened_filepath"] = filepath
	serialize(StreamPeerFile.open(filepath, FileAccess.WRITE))


func serialize(
		stream: StreamPeer = StreamPeerFile.open(
			Settings["state/last_opened_filepath"],
			FileAccess.WRITE
		)
	) -> void:
	var json := var_to_bytes({
		"xform": draw_xform,
		"elements": WhiteboardManager.serialize(elements),
	})
	var json_compressed := json.compress(FileAccess.COMPRESSION_ZSTD)
	stream.put_u64(json.size())
	stream.put_data(json_compressed)


func deserialize(stream: StreamPeer) -> void:
	var json_size := stream.get_u64()
	var json_compressed: PackedByteArray =  stream.get_data(stream.get_available_bytes())[1]
	var data = bytes_to_var(json_compressed.decompress(json_size, FileAccess.COMPRESSION_ZSTD))
	reset()
	elements = WhiteboardManager.deserialize(data.elements)
	for element_index in elements.size():
		layer_container.add_child(create_layer(element_index))
	draw_xform = data.xform


func reset() -> void:
	draw_xform = Transform2D()
	elements.clear()
	preview_elements.clear()
	redraw_preview()
	for child in layer_container.get_children():
		child.queue_free()


func create_layer(index: int) -> ElementLayer:
	var layer := ElementLayer.new()
	layer.index = index
	layer.whiteboard = self
	return layer


class PreviewControl extends Node2D:
	var wb: Whiteboard
	
	func _draw() -> void:
		for preview_element in wb.preview_elements:
			preview_element.draw(self, wb)


class ElementLayer extends Node2D:
	var whiteboard: Whiteboard
	var index: int
	
	func _draw() -> void:
		var element := whiteboard.elements[index]
		if DebugManager.show_bounds:
			var bounds := element.get_bounding_box()
			var draw_scale_cache := whiteboard.draw_scale
			draw_rect(bounds, Color.RED, false, 2.0 / draw_scale_cache)
		element.draw(self, whiteboard)
