@tool
extends Node


enum Severity {
	INFO,
	SUCCESS,
	WARNING,
	ERROR,
}


signal toast_pushed(severity: Severity, message: String, custom_control: Control)


var toast_queue: Array[Dictionary]
var toasts_active: bool = false:
	set(value):
		var old_toasts_active := toasts_active
		toasts_active = value
		if not old_toasts_active and toasts_active:
			while not toast_queue.is_empty():
				var toast = toast_queue.pop_front()
				push_toast(toast.severity, toast.message, toast.custom_control)


func push_toast(severity: Severity, message: String, custom_control: Control = null):
	if toasts_active:
		toast_pushed.emit(severity, message, custom_control)
	else:
		toast_queue.push_back({
			"severity": severity,
			"message": message,
			"custom_control": custom_control,
		})
