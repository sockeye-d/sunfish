@tool
class_name ToolPopup extends RadialPopup


var selected_tools: Array[Script]


func _ready() -> void:
	Settings.setting_changed("core/tool_layout").connect(update_tools)


func update_tools(layout: Array[StringName] = Settings["core/tool_layout"]) -> void:
	items.clear()
	if layout.is_empty():
		return
	for tool_id: StringName in layout:
		var tool := WhiteboardManager.tools[tool_id]
		if not tool.is_visible():
			continue
		var item := ToolItem.new()
		var icon := IconTexture2D.create(tool.get_id(), 4.0)
		item.icon = icon
		item.tool = tool
		item.tool_popup = self
		items.append(item)
	visual.queue_redraw()


func should_hide(event: InputEvent) -> bool:
	return event.is_match(Settings["shortcuts/show_tool_pie"]) and not event.is_pressed()


class ToolItem extends Item:
	var tool_popup: ToolPopup
	var icon: Texture2D
	var tool: Script
	var hovered: bool

	func is_enabled() -> bool: return tool not in tool_popup.selected_tools

	func get_size() -> Vector2: return icon.get_size()

	func draw(canvas: Control, rect: Rect2, highlight_factor: float, opacity: float) -> void:
		canvas.draw_texture_rect(
			icon, rect, false,
			(Color.WHITE.lerp(ThemeManager.active_theme.accent_0, highlight_factor) if is_enabled() else Color(1, 1, 1, 0.5)) * Color(1, 1, 1, opacity)
		)
