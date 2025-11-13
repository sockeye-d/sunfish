@tool
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "dev.fishies.svg_import_plugin"

func _get_visible_name() -> String:
	return "SVG"

func _get_recognized_extensions() -> PackedStringArray:
	return ["svg"]

func _get_save_extension() -> String:
	return "svg"

func _get_resource_type() -> String:
	return "SVG"

func _get_preset_count() -> int:
	return 1

func _get_preset_name(preset_index: int) -> String:
	return "Default"

func _get_import_options(path, preset_index) -> Array[Dictionary]:
	return []

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var file := FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FAILED
	var filename := save_path + "." + _get_save_extension()
	var save_file := FileAccess.open(filename, FileAccess.WRITE)
	if save_file == null:
		return FileAccess.get_open_error()
	if not save_file.store_string(file.get_as_text()):
		return FAILED
	return OK

class SVGInspectorPlugin extends EditorInspectorPlugin:
	func _can_handle(object: Object) -> bool: return object is SVG

	func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
		if name != "source":
			return false
		var svg := object as SVG
		if svg == null:
			return false
		var svg_image := Image.new()
		if svg_image.load_svg_from_string(svg.source) != OK:
			return false
		var label := Label.new()
		label.text = "%s×%s" % [svg_image.get_width(), svg_image.get_height()]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var control := FlowContainer.new()
		control.alignment = FlowContainer.ALIGNMENT_CENTER
		for scale in PackedFloat32Array([1.0, 1.5, 2.0]):
			var preview := SVGPreview.new()
			preview.svg_source = svg.source
			preview.svg_scale = scale
			control.add_child(preview)
		var btn := Button.new()
		btn.text = "Show source"
		btn.toggle_mode = true
		var source_label := Label.new()
		source_label.text = svg.source
		source_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		source_label.hide()
		btn.toggled.connect(func(toggled: bool): source_label.visible = toggled)
		add_custom_control(label)
		add_custom_control(control)
		add_custom_control(btn)
		add_custom_control(source_label)
		return true


class SVGPreview extends TextureRect:
	var svg_source: String
	var svg_scale: float

	func _ready() -> void:
		var svg_image := Image.new()
		svg_image.load_svg_from_string(svg_source, svg_scale)
		texture = ImageTexture.create_from_image(svg_image)
		expand_mode = TextureRect.EXPAND_KEEP_SIZE
		stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		custom_minimum_size.y = 32
		if texture.get_size().y > 128:
			expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			stretch_mode = TextureRect.STRETCH_SCALE
			custom_minimum_size.x = 128
			custom_minimum_size.y = 128
