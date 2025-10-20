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
	
	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void:
		canvas.material = Inner.erase_material
		super.draw(canvas, wb)


class EraserDotElement extends BrushTool.BrushDotElement:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(EraserDotElement)
	
	static func get_id() -> String: return "dev.fishies.sunfish.EraserDotElement"
	
	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void:
		canvas.material = Inner.erase_material
		super.draw(canvas, wb)


class Inner:
	static var erase_material: CanvasItemMaterial:
		get:
			if not erase_material:
				erase_material = CanvasItemMaterial.new()
				erase_material.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
			return erase_material
