class_name StatusBox extends Control


@onready var position_label: Label = %PositionLabel
@onready var zoom_label: Label = %ZoomLabel
@onready var tool_label: Label = %ToolLabel
@onready var fps_label: Label = %FPSLabel
@onready var stroke_label: Label = %StrokeLabel
@onready var saved_indicator: TextureRect = %SavedIndicator


@export var whiteboard: Whiteboard


@export var saved_texture: IconTexture2D
@export var unsaved_texture: IconTexture2D


func _ready() -> void:
	whiteboard.active_tools_changed.connect(_update_text)
	whiteboard.xform_changed.connect(_update_text)
	whiteboard.element_count_changed.connect(_update_text)
	
	_update_text()
	
	WhiteboardBus.save_status_changed.connect(func(saved: bool):
		saved_indicator.texture = saved_texture if saved else unsaved_texture
	)
	saved_indicator.texture = saved_texture


func _process(delta: float) -> void:
	Util.unused(delta)
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func _update_text() -> void:
	var x_text := String.num(whiteboard.inv_draw_xform.get_origin().x, 0)
	var y_text := String.num(whiteboard.inv_draw_xform.get_origin().y, 0)
	position_label.text = "Position: %s, %s" % [
		x_text.lpad(maxi(x_text.length(), y_text.length())),
		y_text.lpad(maxi(x_text.length(), y_text.length())),
	]
	zoom_label.text = "Zoom: %.f%%" % (Util.round_sig_figs(whiteboard.draw_scale, 3) * 100.0)
	tool_label.text = "Active tool: %s" % ", ".join(
		whiteboard.active_tools
			.map(func(it: WhiteboardTool): return ReverseDNSUtil.pretty_print(it.get_script().get_id()).trim_suffix("Tool").strip_edges())
	)
	stroke_label.text = "%s strokes" % [
		whiteboard.active_element_count,
	]
