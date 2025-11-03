extends BrushTool


const BrushTool = preload("BrushTool.gd")


static func get_id() -> StringName: return "dev.fishies.sunfish.EraserTool"


static func get_shortcut() -> InputEvent: return Shortcuts.key(KEY_E)


func should_hide_mouse() -> bool: return true


func create_brush_element() -> BrushElement: return EraserElement.new()
func create_dot_element() -> BrushDotElement: return EraserDotElement.new()


func _get_default_width() -> float: return 30.0
func _do_pressure() -> bool: return false


func _validate_property(property: Dictionary) -> void:
	if property.name == "width":
		property.hint_string = "1.0,%s,0.0,or_greater" % _get_default_width()


class EraserElement extends BrushTool.BrushElement:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(EraserElement)

	static func get_id() -> StringName: return "dev.fishies.sunfish.EraserElement"

	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void:
		canvas.material = Inner.erase_material
		super.draw(canvas, wb)

	static func deserialize(data: Dictionary) -> Element:
		var el := EraserElement.new()
		_deserialize(el, data)
		return el


class EraserDotElement extends BrushTool.BrushDotElement:
	static func _static_init() -> void:
		WhiteboardManager.register_deserializer(EraserDotElement)

	static func get_id() -> StringName: return "dev.fishies.sunfish.EraserDotElement"

	func draw(canvas: Whiteboard.ElementLayer, wb: Whiteboard) -> void:
		canvas.material = Inner.erase_material
		super.draw(canvas, wb)

	static func deserialize(data: Dictionary) -> Element:
		var el := EraserDotElement.new()
		_deserialize(el, data)
		return el


class Inner:
	static var erase_material: CanvasItemMaterial:
		get:
			if not erase_material:
				erase_material = CanvasItemMaterial.new()
				erase_material.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
			return erase_material
