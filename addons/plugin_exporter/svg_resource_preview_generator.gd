@tool
extends EditorResourcePreviewGenerator


func _can_generate_small_preview() -> bool: return true


func _generate(resource: Resource, size: Vector2i, metadata: Dictionary) -> Texture2D:
	var svg := resource as SVG
	if svg == null: return null
	var img := Image.new()
	img.load_svg_from_string(svg.source)
	var scaling_factor := Vector2(size) / Vector2(img.get_size())
	img.load_svg_from_string(svg.source, scaling_factor[scaling_factor.min_axis_index()])
	return ImageTexture.create_from_image(img)


func _handles(type: String) -> bool:
	return type == "SVG"
