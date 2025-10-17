class_name StatusBox extends Control


@onready var position_label: Label = %PositionLabel
@onready var zoom_label: Label = %ZoomLabel
@onready var tool_label: Label = %ToolLabel
@onready var fps_label: Label = %FPSLabel
@onready var stroke_label: Label = %StrokeLabel


@export var whiteboard: Whiteboard


func _ready() -> void:
	whiteboard.active_tools_changed.connect(_update_text)
	whiteboard.xform_changed.connect(_update_text)
	whiteboard.element_count_changed.connect(_update_text)
	
	_update_text()


func _process(delta: float) -> void:
	Util.unused(delta)
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func _update_text() -> void:
	position_label.text = "Position: %05d, %05d" % [whiteboard.inv_draw_xform.get_origin().x, whiteboard.inv_draw_xform.get_origin().y]
	zoom_label.text = "Zoom: %.f%%" % (Util.round_sig_figs(whiteboard.draw_scale, 3) * 100.0)
	tool_label.text = "Active tool: %s" % ", ".join(
		whiteboard.active_tools
			.map(func(it: WhiteboardTool): return ReverseDNSUtil.pretty_print(it.get_script().get_id()).trim_suffix("Tool").strip_edges())
	)
	stroke_label.text = "%s strokes" % [
		whiteboard.active_element_count,
	]
