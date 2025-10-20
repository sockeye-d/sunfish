extends WhiteboardTool


static func get_id() -> StringName: return "dev.fishies.sunfish.SelectTool"


func receive_input(wb: Whiteboard, event: InputEvent) -> Display:
	Util.unused(wb)
	Util.unused(event)
	return null
