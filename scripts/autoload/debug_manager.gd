extends Node


var show_bounds: bool = false
var giant_brush_deadzone: bool = false


func show_random_toast() -> void:
	ToastManager.push_toast(randi_range(0, ToastManager.Severity.size() - 1) as ToastManager.Severity, "hi")
