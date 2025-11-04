const TOOLS: Array[Script] = [
	preload("BrushTool.gd"),
	preload("EraserTool.gd"),
	preload("LineTool.gd"),
	preload("CircleTool.gd"),
	preload("FilledCircleTool.gd"),
	preload("RectangleTool.gd"),
	preload("FilledRectangleTool.gd"),
	preload("ImageTool.gd"),
	preload("TextTool.gd"),
	preload("BookmarkTool.gd"),
	preload("ScreenshotTool.gd"),
]


static func _static_init() -> void:
	for tool in TOOLS:
		WhiteboardManager.register_tool(tool)
