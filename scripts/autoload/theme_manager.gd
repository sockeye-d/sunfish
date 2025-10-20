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


@onready var theme_res: Theme = load("res://main_theme.tres")


signal themes_changed
signal ui_scale_changed
signal background_color_changed(new_color: Color)


var ui_scale: float:
	set(value):
		ui_scale = value
		ui_scale_changed.emit()
var themes: Dictionary[String, ThemeColors]
var active_theme: ThemeColors


func _ready() -> void:
	ui_scale_changed.connect(func(): RenderingServer.global_shader_parameter_set("ui_scale", ui_scale))
	ui_scale_changed.connect(func(): get_tree().root.content_scale_factor = ui_scale)
	ui_scale = get_tree().root.content_scale_factor
	
	set_theme_id(Settings["dev.fishies.sunfish.config.general/theme"])


func unregister_theme(id: String) -> void:
	if id in themes:
		themes.erase(id)
		themes_changed.emit()


func register_theme(theme: ThemeColors) -> void:
	themes[theme.id] = theme
	for theme_key in themes:
		if not is_instance_valid(themes[theme_key]):
			themes.erase(theme_key)
	themes_changed.emit()


@warning_ignore_start("integer_division")
func set_theme(new_theme: ThemeColors) -> void:
	active_theme = new_theme
	var theme: ThemeColors = new_theme.duplicate()
	RenderingServer.set_default_clear_color(theme.background_1)
	if Engine.is_editor_hint():
		ProjectSettings["rendering/environment/defaults/default_clear_color"] = theme.background_1
	
	var selection := Color(theme.accent_0, 0.3)
	var disabled_surface := theme.surface.lerp(theme.background_0, 0.5)
	var darkest_bg := get_darkest(theme.background_0, theme.background_1, theme.background_2)
	var shadow_color := Color(darkest_bg, 0.5)
	var base_spacing := 8 if OS.has_feature("mobile") else 4
	var base_font_size := 12 if OS.has_feature("mobile") else 16
	var shadow := func(sb: StyleBoxFlat) -> StyleBoxFlat:
		return shadowed(sb, shadow_color, 2, 0, base_spacing / 2)
	
	theme_res.set_block_signals(true)
	get_tree().root.theme = theme_res
	theme_res.default_font = SANS
	theme_res.default_font_size = base_font_size
	
	theme_res.set_font("font", "HeaderLarge", SERIF_BOLD)
	theme_res.set_font_size("font_size", "HeaderLarge", int(base_font_size * 1.5))
	theme_res.set_font("font", "HeaderMedium", SANS_BOLD)
	theme_res.set_font_size("font_size", "HeaderMedium", int(base_font_size * 1.125))
	theme_res.set_font("font", "HeaderSmall", SANS)
	theme_res.set_font_size("font_size", "HeaderSmall", base_font_size)
	
	theme_res.set_constant("separation", "BoxContainer", base_spacing)
	theme_res.set_constant("separation", "HBoxContainer", base_spacing)
	theme_res.set_constant("separation", "VBoxContainer", base_spacing)
	
	theme_res.set_constant("margin_bottom", "MarginContainer", base_spacing)
	theme_res.set_constant("margin_top", "MarginContainer", base_spacing)
	theme_res.set_constant("margin_left", "MarginContainer", base_spacing)
	theme_res.set_constant("margin_right", "MarginContainer", base_spacing)
	
	theme_res.set_stylebox("panel", "PanelContainer", new_flat(theme.background_0, [base_spacing * 2], [base_spacing]))
	theme_res.set_stylebox("panel", "SettingsPanelContainer", new_flat(theme.background_0, [0, base_spacing * 2, base_spacing * 2, base_spacing * 2], [base_spacing]))
	theme_res.set_stylebox("panel", "Panel", new_flat(theme.background_0, [base_spacing * 2], [base_spacing]))
	
	theme_res.set_constant("scrollbar_h_separation", "Tree", base_spacing)
	
	theme_res.set_color("font_color", "Tree", theme.text)
	theme_res.set_color("font_disabled_color", "Tree", theme.subtext)
	theme_res.set_color("font_hovered_color", "Tree", theme.text)
	theme_res.set_color("font_hovered_dimmed_color", "Tree", theme.text)
	theme_res.set_color("font_hovered_selected_color", "Tree", theme.text)
	theme_res.set_color("font_selected_color", "Tree", theme.text)
	theme_res.set_color("children_hl_line_color", "Tree", theme.surface_hover)
	theme_res.set_color("parent_hl_line_color", "Tree", theme.overlay)
	theme_res.set_color("relationship_line_color", "Tree", theme.surface)
	
	theme_res.set_stylebox("panel", "Tree", new_flat(theme.background_0, [base_spacing * 2], [base_spacing]))
	theme_res.set_stylebox("hovered", "Tree", new_flat(theme.surface_hover, [base_spacing], [base_spacing]))
	theme_res.set_stylebox("selected", "Tree", new_flat(theme.surface_hover, [base_spacing], [base_spacing]))
	theme_res.set_stylebox("hovered_dimmed", "Tree", new_flat(theme.surface, [base_spacing], [base_spacing]))
	theme_res.set_stylebox("hovered_selected", "Tree", new_flat(theme.surface_press, [base_spacing], [base_spacing]))
	
	theme_res.set_color("font_color", "Label", theme.text)
	
	theme_res.set_color("font_color", "SubtextLabel", theme.subtext)
	
	theme_res.set_color("font_color", "Button", theme.text)
	theme_res.set_color("font_pressed_color", "Button", theme.text)
	theme_res.set_color("font_hover_pressed_color", "Button", theme.text)
	theme_res.set_color("font_hover_color", "Button", theme.text)
	theme_res.set_color("font_disabled_color", "Button", theme.subtext)
	theme_res.set_stylebox("normal", "Button", new_flat(theme.surface, [base_spacing], [base_spacing]))
	theme_res.set_stylebox("hover", "Button", new_flat(theme.surface_hover, [base_spacing], [base_spacing]))
	theme_res.set_stylebox("pressed", "Button", shadow.call(new_flat(theme.surface_press, [base_spacing], [base_spacing])))
	theme_res.set_stylebox("disabled", "Button", new_flat(disabled_surface, [base_spacing], [base_spacing]))
	
	for clazz in PackedStringArray(["CheckButton", "CheckBox"]):
		theme_res.set_color("font_color", clazz, theme.text)
		theme_res.set_color("font_pressed_color", clazz, theme.text)
		theme_res.set_color("font_hover_pressed_color", clazz, theme.text)
		theme_res.set_color("font_hover_color", clazz, theme.text)
		theme_res.set_color("font_disabled_color", clazz, theme.subtext)
		theme_res.set_stylebox("normal", clazz, new_flat(theme.surface, [base_spacing], [base_spacing]))
		theme_res.set_stylebox("hover", clazz, new_flat(theme.surface_hover, [base_spacing], [base_spacing]))
		theme_res.set_stylebox("pressed", clazz, shadow.call(new_flat(theme.surface_press, [base_spacing], [base_spacing])))
		theme_res.set_stylebox("hover_pressed", clazz, shadow.call(new_flat(theme.surface_press, [base_spacing], [base_spacing])))
		theme_res.set_stylebox("disabled", clazz, new_flat(disabled_surface, [base_spacing], [base_spacing]))
	
	theme_res.set_color("font_color", "ProgressBar", theme.text)
	theme_res.set_stylebox("background", "ProgressBar", new_flat(theme.surface, [base_spacing], [base_spacing]))
	theme_res.set_stylebox("fill", "ProgressBar", new_flat(theme.overlay, [base_spacing], [base_spacing]))
	
	theme_res.set_stylebox("panel", "PopupPanel", shadow.call(new_flat(theme.background_1, [base_spacing], [base_spacing])))
	
	theme_res.set_stylebox("panel", "AcceptDialog", new_flat(theme.background_1, [base_spacing], [base_spacing]))
	
	theme_res.set_color("font_color", "LineEdit", theme.text)
	theme_res.set_color("caret_color", "LineEdit", theme.text)
	theme_res.set_color("font_selected_color", "LineEdit", theme.text)
	theme_res.set_color("font_uneditable_color", "LineEdit", theme.subtext)
	theme_res.set_color("font_placeholder_color", "LineEdit", Color(theme.subtext, 0.5))
	theme_res.set_color("selection_color", "LineEdit", selection)
	theme_res.set_stylebox("normal", "LineEdit", new_flat(theme.surface, [base_spacing], [base_spacing]))
	theme_res.set_stylebox("read_only", "LineEdit", new_flat(disabled_surface, [base_spacing], [base_spacing]))
	
	theme_res.set_color("font_color", "TextEdit", theme.text)
	theme_res.set_color("font_selected_color", "TextEdit", theme.text)
	theme_res.set_color("font_uneditable_color", "TextEdit", theme.subtext)
	theme_res.set_color("selection_color", "TextEdit", selection)
	theme_res.set_stylebox("normal", "TextEdit", new_flat(theme.surface, [base_spacing], [base_spacing]))
	
	var tab_radii: PackedInt32Array = [base_spacing, base_spacing, 0, 0]
	theme_res.set_stylebox("panel", "TabContainer", new_flat(theme.background_0, tab_radii, [base_spacing]))
	theme_res.set_stylebox("tab_disabled", "TabContainer", blended(new_flat(theme.background_1, tab_radii, [base_spacing], [0, 0, 0, 8], theme.background_0)))
	theme_res.set_stylebox("tab_unselected", "TabContainer", blended(new_flat(theme.surface, tab_radii, [base_spacing], [0, 0, 0, 8], theme.background_0)))
	theme_res.set_stylebox("tab_selected", "TabContainer", new_flat(theme.surface_press, tab_radii, [base_spacing], [0, 0, 0, base_spacing / 2], theme.accent_0))
	theme_res.set_stylebox("tab_hovered", "TabContainer", blended(new_flat(theme.surface_hover, tab_radii, [base_spacing], [0, 0, 0, 8], theme.background_0)))
	theme_res.set_color("font_disabled_color", "TabContainer", theme.subtext)
	theme_res.set_color("font_hovered_color", "TabContainer", theme.text)
	theme_res.set_color("font_selected_color", "TabContainer", theme.text)
	theme_res.set_color("font_unselected_color", "TabContainer", theme.text)
	
	theme_res.set_stylebox("panel", "SliderCombo", new_flat(theme.background_1, [base_spacing], [base_spacing]))
	
	theme_res.set_stylebox("slider", "HSlider", new_flat(theme.surface, [base_spacing / 2], [0, base_spacing / 2]))
	theme_res.set_stylebox("grabber_area", "HSlider", new_flat(theme.overlay_hover, [base_spacing / 2], [0, base_spacing / 2]))
	theme_res.set_stylebox("grabber_area_highlight", "HSlider", new_flat(theme.overlay_press, [base_spacing / 2], [0, base_spacing / 2]))
	
	theme_res.set_stylebox("slider", "VSlider", new_flat(theme.surface, [base_spacing / 2], [base_spacing / 2, 0]))
	theme_res.set_stylebox("grabber_area", "VSlider", new_flat(theme.overlay_hover, [base_spacing / 2], [base_spacing / 2, 0]))
	theme_res.set_stylebox("grabber_area_highlight", "VSlider", new_flat(theme.overlay_press, [base_spacing / 2], [base_spacing / 2, 0]))
	theme_res.set_icon("grabber", "VSlider", theme_res.get_icon("grabber", "HSlider"))
	theme_res.set_icon("grabber_highlight", "VSlider", theme_res.get_icon("grabber_highlight", "HSlider"))
	
	theme_res.set_stylebox("grabber", "HScrollBar", new_flat(theme.overlay, [base_spacing / 2], [0, base_spacing / 2]))
	theme_res.set_stylebox("grabber_highlight", "HScrollBar", new_flat(theme.overlay_hover, [base_spacing / 2], [0, base_spacing / 2]))
	theme_res.set_stylebox("grabber_pressed", "HScrollBar", new_flat(theme.overlay_press, [base_spacing / 2], [0, base_spacing / 2]))
	theme_res.set_stylebox("scroll", "HScrollBar", new_flat(theme.surface, [base_spacing / 2], [0, base_spacing / 2]))
	
	theme_res.set_stylebox("grabber", "VScrollBar", new_flat(theme.overlay, [base_spacing / 2], [base_spacing / 2, 0]))
	theme_res.set_stylebox("grabber_highlight", "VScrollBar", new_flat(theme.overlay_hover, [base_spacing / 2], [base_spacing / 2, 0]))
	theme_res.set_stylebox("grabber_pressed", "VScrollBar", new_flat(theme.overlay_press, [base_spacing / 2], [base_spacing / 2, 0]))
	theme_res.set_stylebox("scroll", "VScrollBar", new_flat(theme.surface, [base_spacing / 2], [base_spacing / 2, 0]))
	
	theme_res.set_stylebox("separator", "VSeparator", new_flat(disabled_surface, [1], [1, 0], [0, 0]))
	theme_res.set_stylebox("separator", "HSeparator", new_flat(disabled_surface, [1], [0, 1], [0, 0]))
	
	theme_res.set_color("font_color", "PopupMenu", theme.text)
	theme_res.set_color("font_disabled_color", "PopupMenu", theme.subtext)
	theme_res.set_color("font_accelerator_color", "PopupMenu", theme.subtext)
	theme_res.set_color("font_hover_color", "PopupMenu", theme.text)
	theme_res.set_color("font_separator_color", "PopupMenu", theme.subtext)
	
	theme_res.set_stylebox("panel", "PopupMenu", shadow.call(new_flat(theme.background_1, [base_spacing * 2], [base_spacing])))
	theme_res.set_stylebox("hover", "PopupMenu", shadow.call(new_flat(theme.overlay, [base_spacing], [base_spacing])))
	theme_res.set_stylebox("separator", "PopupMenu", new_flat(theme.surface, [1], [0, 1], [0, 0]))
	theme_res.set_stylebox("labeled_separator_left", "PopupMenu", new_flat(theme.surface, [1], [0, 1], [0, 0]))
	theme_res.set_stylebox("labeled_separator_right", "PopupMenu", new_flat(theme.surface, [1], [0, 1], [0, 0]))
	for prefix in PackedStringArray(["", "radio_"]):
		for icon in PackedStringArray(["checked", "unchecked"]):
			for suffix in PackedStringArray(["", "_disabled"]):
				var icon_name := prefix + icon + suffix
				theme_res.set_icon(icon_name, "PopupMenu", theme_res.get_icon(icon_name, "CheckBox"))
	
	# is this wasteful?  yes
	# does it work? also yes
	var focus_sb := new_flat(Color.TRANSPARENT, [base_spacing + 1], [base_spacing], [base_spacing / 2], theme.subtext, [base_spacing / 2])
	for prop in theme_res.get_property_list():
		if prop.class_name == "Texture2D" and prop.name.match("?Slider/icons/grabber*"):
			var val := theme_res.get(prop.name) as IconTexture2D
			if val:
				val.secondary_icon_scale = base_spacing / 4.0
	for prop in ThemeDB.get_default_theme().get_property_list():
		if prop.class_name == "StyleBox" and prop.name.match("*/focus"):
			theme_res.set(prop.name, focus_sb)
	
	theme_res.set_block_signals(false)
	theme_res.emit_changed()
	background_color_changed.emit(theme.background_1)
	IconTexture2D.text_color = theme.text
	IconTexture2D.bg_color = theme.background_0
	IconTexture2D.SignalBus.instance.update.emit()
	
	if Engine.is_editor_hint():
		ResourceSaver.save(theme_res, theme_res.resource_path)
@warning_ignore_restore("integer_division")


func set_theme_id(id: String) -> void:
	if id in themes:
		set_theme(themes[id])
	else:
		printerr("Couldn't find theme %s" % id)


func reload_theme() -> void:
	if active_theme:
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


func shadowed(sb: StyleBoxFlat, color: Color, size: int, x_offset: float, y_offset: float) -> StyleBoxFlat:
	sb.shadow_color = color
	sb.shadow_size = size
	sb.shadow_offset = Vector2(x_offset, y_offset)
	return sb


func blended(sb: StyleBoxFlat, blend := true) -> StyleBoxFlat:
	sb.border_blend = blend
	return sb


func get_darkest(...colors: Array) -> Color:
	var darkest := Color.WHITE
	for color: Color in colors:
		if color.get_luminance() < darkest.get_luminance():
			darkest = color
	return darkest
