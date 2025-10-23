@tool
class_name ToolPopup extends PopupPanel


const RADIUS = 125.0
const DEADZONE = 50.0


signal tool_selected(new_tool: Script)


var tool_button_group := ButtonGroup.new()
var tool_instances: Dictionary[Script, WhiteboardTool]


@export var whiteboard: Whiteboard
@warning_ignore("unused_private_class_variable")
@export_tool_button("Update tools") var __ := _update_tools


var tools: Dictionary[Script, ToolButtonState]
var selected_tool_id: String
var visual = Visual.new()


var center_pos: Vector2
var mouse_pos: Vector2
var selected_tools: Array[Script]


func _init() -> void:
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.t = self
	add_child(visual)
	
	exclusive = true


func _ready() -> void:
	about_to_popup.connect(func():
		add_theme_stylebox_override("panel", get_theme_stylebox("panel", "ToolPopup"))
	)


func _update_tools() -> void:
	tools.clear()
	if WhiteboardManager.tools.is_empty():
		return
	for tool_id in WhiteboardManager.tools:
		var tool := WhiteboardManager.tools[tool_id]
		if not tool.is_visible():
			continue
		var state := ToolButtonState.new()
		var icon := IconTexture2D.create(tool.get_id(), 4.0)
		state.icon = icon
		state.tool = tool
		tools[tool] = state
	visual.queue_redraw()


func _input(event: InputEvent) -> void:
	if event.is_match(Settings["shortcuts/show_tool_pie"]) and not event.is_pressed():
		var index := roundf(mouse_pos.angle() / TAU * tools.size())
		var tool = tools.values()[index].tool
		if mouse_pos.length() > DEADZONE and tool not in selected_tools:
			tool_selected.emit(tool)
		hide()
		set_input_as_handled()
	var mm := event as InputEventMouseMotion
	if mm:
		if not mm.relative.is_zero_approx():
			mouse_pos = mm.global_position - center_pos
			visual.queue_redraw()


func set_selected(tool: Script) -> void:
	tools[tool].button_pressed = true


class ToolButtonState:
	var icon: Texture2D
	var tool: Script
	var hovered: bool


class Visual extends Control:
	const TRIANGLE_POINTS: PackedVector2Array = [
		Vector2.ZERO,
		Vector2(1, 1),
		Vector2(1, -1),
	]
	var t: ToolPopup
	
	
	func _draw() -> void:
		var index := 0
		var center := t.center_pos
		var mouse_angle := t.mouse_pos.angle()
		var angle_per_index := TAU / t.tools.size()
		var outside_deadzone_fac := smoothstep(DEADZONE, DEADZONE + 30.0, t.mouse_pos.length())
		draw_circle(center, RADIUS, ThemeManager.active_theme.background_1, false, 64.0, true)
		draw_circle(center, DEADZONE, ThemeManager.active_theme.overlay.lerp(ThemeManager.active_theme.overlay_press, outside_deadzone_fac), false, 2.0 + 2.0 * outside_deadzone_fac, true)
		draw_arc(center, RADIUS, mouse_angle - angle_per_index * 0.5, mouse_angle + angle_per_index * 0.5, 32, Color(ThemeManager.active_theme.surface, outside_deadzone_fac), 64.0, true)
		for tool_id in t.tools:
			var state := t.tools[tool_id]
			var is_selected: bool = state.tool in t.selected_tools
			var angle := index * angle_per_index
			var angle_vec := Vector2.from_angle(angle)
			var draw_pos_center := center + angle_vec * Vector2(125, 125)
			var fac := pow(ease(1.0 - clampf(absf(angle_vec.angle_to(t.mouse_pos) / angle_per_index * 0.5 + 0.0) - 0.0, 0.0, 1.0), -2.0), 4.0) * outside_deadzone_fac
			var draw_scale := 0.5 if is_selected else lerpf(0.5, 1.0, fac)
			var tex_rect := Rect2(draw_pos_center - state.icon.get_size() * 0.5 * draw_scale, state.icon.get_size() * draw_scale)
			draw_texture_rect(state.icon, tex_rect, false, Color(1, 1, 1, 0.5) if is_selected else Color.WHITE.lerp(ThemeManager.active_theme.accent_0, fac))
			index += 1
