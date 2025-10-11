@tool
extends Node


const CODE_BOLD = preload("uid://jnq1s0lk0816")
const CODE_BOLD_ITALIC = preload("uid://b22yigk55md24")
const CODE_ITALIC = preload("uid://c71fx3mno2v3x")
const CODE = preload("uid://882ertswqdgg")
const SANS_BOLD = preload("uid://13ebtoj6jkry")
const SANS_BOLD_ITALIC = preload("uid://xrg0sc2qgn1j")
const SANS_ITALIC = preload("uid://bgtlbnv0pvhiy")
const SANS = preload("uid://cm1owo44e6kug")
const SERIF_BOLD = preload("uid://y3da3t84kupb")
const SERIF_BOLD_ITALIC = preload("uid://codfjr5fnfhy8")
const SERIF_ITALIC = preload("uid://dgk7hn73us187")
const SERIF = preload("uid://dyte8f36cqfjo")


var theme_res: Theme


signal ui_scale_changed
signal background_color_changed(new_color: Color)


var ui_scale: float:
	set(value):
		ui_scale = value
		ui_scale_changed.emit()
var themes: Dictionary[String, ThemeColors]
var active_theme: ThemeColors


func _ready() -> void:
	theme_res = load("res://main_theme.tres")
	ui_scale_changed.connect(func(): RenderingServer.global_shader_parameter_set("ui_scale", ui_scale))
	ui_scale_changed.connect(func(): get_tree().root.content_scale_factor = ui_scale)


func register_theme(theme: ThemeColors) -> void:
	themes[theme.id] = theme


func set_theme(theme: ThemeColors) -> void:
	active_theme = theme
	
	var selection := Color(theme.accent_0, 0.3)
	var disabled_surface := theme.surface.lerp(theme.background_0, 0.5)
	
	theme_res.set_block_signals(true)
	theme_res.default_font = SANS
	
	theme_res.set_stylebox("panel", "PanelContainer", new_flat(theme.background_0, [4], [4]))
	theme_res.set_stylebox("panel", "Panel", new_flat(theme.background_0, [4], [4]))
	
	theme_res.set_color("font_color", "Label", theme.text)
	
	theme_res.set_color("font_color", "SubtextLabel", theme.subtext)
	
	theme_res.set_color("font_color", "Button", theme.text)
	theme_res.set_color("font_pressed_color", "Button", theme.text)
	theme_res.set_color("font_hover_pressed_color", "Button", theme.text)
	theme_res.set_color("font_hover_color", "Button", theme.subtext)
	theme_res.set_stylebox("normal", "Button", new_flat(theme.surface, [4], [4]))
	theme_res.set_stylebox("hover", "Button", new_flat(theme.surface_hover, [4], [4]))
	theme_res.set_stylebox("pressed", "Button", new_flat(theme.surface_press, [4], [4]))
	theme_res.set_stylebox("disabled", "Button", new_flat(disabled_surface, [4], [4]))
	
	theme_res.set_color("font_color", "PopupMenu", theme.text)
	theme_res.set_color("font_disabled_color", "PopupMenu", theme.subtext)
	theme_res.set_color("font_hover_color", "PopupMenu", theme.text)
	theme_res.set_stylebox("panel", "PopupMenu", new_flat(theme.background_1, [4], [4]))
	theme_res.set_stylebox("hover", "PopupMenu", new_flat(theme.overlay, [4], [4]))
	
	theme_res.set_stylebox("panel", "PopupPanel", new_flat(theme.background_1, [4], [4]))
	
	theme_res.set_stylebox("panel", "PopupPanel", new_flat(theme.background_1, [4], [4]))
	
	theme_res.set_color("font_color", "LineEdit", theme.text)
	theme_res.set_color("font_selected_color", "LineEdit", theme.text)
	theme_res.set_color("font_uneditable_color", "LineEdit", theme.subtext)
	theme_res.set_color("selection_color", "LineEdit", selection)
	theme_res.set_stylebox("normal", "LineEdit", new_flat(theme.surface, [4], [4]))
	theme_res.set_stylebox("read_only", "LineEdit", new_flat(disabled_surface, [4], [4]))
	
	theme_res.set_color("font_color", "TextEdit", theme.text)
	theme_res.set_color("font_selected_color", "TextEdit", theme.text)
	theme_res.set_color("font_uneditable_color", "TextEdit", theme.subtext)
	theme_res.set_color("selection_color", "TextEdit", selection)
	theme_res.set_stylebox("normal", "TextEdit", new_flat(theme.surface, [4], [4]))
	
	var tab_radii: PackedInt32Array = [4, 4, 0, 0]
	theme_res.set_stylebox("tab_unselected", "TabContainer", new_flat(theme.surface, tab_radii, [4]))
	theme_res.set_stylebox("tab_selected", "TabContainer", new_flat(theme.surface_press, tab_radii, [4], [0, 0, 0, 2], theme.accent_0))
	theme_res.set_stylebox("tab_hovered", "TabContainer", new_flat(theme.surface_hover, tab_radii, [4]))
	theme_res.set_color("font_disabled_color", "TabContainer", theme.subtext)
	theme_res.set_color("font_hovered_color", "TabContainer", theme.text)
	theme_res.set_color("font_selected_color", "TabContainer", theme.text)
	theme_res.set_color("font_unselected_color", "TabContainer", theme.text)
	
	theme_res.set_block_signals(false)
	theme_res.emit_changed()
	background_color_changed.emit(theme.background_1)
	IconTexture2D.SignalBus.instance.change_text_color.emit.call_deferred(theme.text)
	
	ResourceSaver.save(theme_res, theme_res.resource_path)


func set_theme_id(id: String) -> void:
	if id in themes:
		set_theme(themes[id])
	else:
		printerr("Couldn't find theme %s" % id)


func reload_theme() -> void:
	set_theme(active_theme)


func new_flat(
		bg_color: Color,
		radii: PackedInt32Array = [0],
		margins: PackedInt32Array = [-1, -1, -1, -1],
		border_width: PackedInt32Array = [0],
		border_color := Color.TRANSPARENT,
		expand_margins: PackedInt32Array = [0]
	) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	# Uses indices relative to the end so that a single-item array will result
	# in all the radii being the same
	sb.corner_radius_top_left = maxi(0, int(radii[-4 % radii.size()]))
	sb.corner_radius_top_right = maxi(0, int(radii[-3 % radii.size()]))
	sb.corner_radius_bottom_left = maxi(0, int(radii[-2 % radii.size()]))
	sb.corner_radius_bottom_right = maxi(0, int(radii[-1 % radii.size()]))
	
	sb.content_margin_left = maxi(-1, int(margins[-4 % margins.size()]))
	sb.content_margin_top = maxi(-1, int(margins[-3 % margins.size()]))
	sb.content_margin_right = maxi(-1, int(margins[-2 % margins.size()]))
	sb.content_margin_bottom = maxi(-1, int(margins[-1 % margins.size()]))
	
	sb.border_width_left = int(border_width[-4 % border_width.size()])
	sb.border_width_top = int(border_width[-3 % border_width.size()])
	sb.border_width_right = int(border_width[-2 % border_width.size()])
	sb.border_width_bottom = int(border_width[-1 % border_width.size()])
	
	sb.expand_margin_left = maxi(-1, int(expand_margins[-4 % expand_margins.size()]))
	sb.expand_margin_top = maxi(-1, int(expand_margins[-3 % expand_margins.size()]))
	sb.expand_margin_right = maxi(-1, int(expand_margins[-2 % expand_margins.size()]))
	sb.expand_margin_bottom = maxi(-1, int(expand_margins[-1 % expand_margins.size()]))
	
	sb.border_color = border_color
	
	sb.bg_color = bg_color
	
	sb.draw_center = true
	
	return sb


func change_bg_color(sb: StyleBoxFlat, bg_color: Color) -> StyleBoxFlat:
	sb.bg_color = bg_color
	return sb


func change_corner_rad(sb: StyleBoxFlat, radii: PackedInt32Array = [0]) -> StyleBoxFlat:
	sb.corner_radius_top_left = radii[0]
	sb.corner_radius_top_right = radii[-3]
	sb.corner_radius_bottom_left = radii[-2]
	sb.corner_radius_bottom_right = radii[-1]
	return sb


func change_content_margins(sb: StyleBox, margins: PackedInt32Array = [0]) -> StyleBox:
	sb.content_margin_left = int(margins[-4 % margins.size()])
	sb.content_margin_top = int(margins[-3 % margins.size()])
	sb.content_margin_right = int(margins[-2 % margins.size()])
	sb.content_margin_bottom = int(margins[-1 % margins.size()])
	return sb
