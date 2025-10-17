extends BrushTool


const BrushTool = preload("BrushTool.gd")


static func get_id() -> String: return "dev.fishies.sunfish.EraserTool"


func should_hide_mouse() -> bool: return true


func create_brush_element() -> BrushElement: return EraserElement.new()
func create_dot_element() -> BrushDotElement: return EraserDotElement.new()


func _get_default_width() -> float: return 15.0


func _validate_property(property: Dictionary) -> void:
	if property.name == "width":
		property.hint_string = "1.0,15.0,0.0,or_greater"


class EraserElement extends BrushTool.BrushElement:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(EraserElement)
	
	static func get_id() -> String: return "dev.fishies.sunfish.EraserElement"
	
	
	func _falloff(x: float) -> float: return max(0.0, 2.0 - 1.0 / x if x <= 1.0 else x)
	
	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void:
		var real_width := _falloff(width * wb.draw_scale) / wb.draw_scale
		if real_width < 0.0:
			return
		if points.size() >= 2:
			canvas.material = Inner.erase_material
			var merged_points := DrawingUtil.merge_close_points(points, pressures, 2.0 / wb.draw_scale)
			DrawingUtil.draw_round_polyline(canvas.get_canvas_item(), merged_points[0], Color.WHITE, real_width, merged_points[1])


class EraserDotElement extends BrushTool.BrushDotElement:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(EraserDotElement)
	
	static func get_id() -> String: return "dev.fishies.sunfish.EraserDotElement"
	
	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void:
		Util.unused(wb)
		canvas.material = Inner.erase_material
		canvas.draw_circle(position, width * 0.5, Color.WHITE)


class Inner:
	static var erase_material: CanvasItemMaterial:
		get:
			if not erase_material:
				erase_material = CanvasItemMaterial.new()
				erase_material.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
			return erase_material
