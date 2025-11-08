@tool
class_name ToastManager


enum Severity {
	INFO,
	SUCCESS,
	WARNING,
	ERROR,
}


static var toast_queue: Array[Dictionary]
static var _toast_handlers: Array[Callable]


static func push_toast(severity: Severity, message: String, additional_controls: Array[Control] = [], custom_control: Control = null):
	if _toast_handlers.size() > 0:
		_call_toast_handlers(severity, message, additional_controls, custom_control)
	else:
		toast_queue.push_back({
			"severity": severity,
			"message": message,
			"additional_controls": additional_controls,
			"custom_control": custom_control,
		})


static func register_toast_handler(handler: Callable) -> void:
	_toast_handlers.append(handler)
	if _toast_handlers.size() == 1:
		while not toast_queue.is_empty():
			var toast = toast_queue.pop_front()
			_call_toast_handlers(toast.severity, toast.message, toast.additional_controls, toast.custom_control)


static func unregister_toast_handler(handler: Callable) -> void:
	_toast_handlers.erase(handler)


static func _call_toast_handlers(severity: Severity, message: String, additional_controls: Array[Control], custom_control: Control) -> void:
	for handler in _toast_handlers:
		handler.call(severity, message, additional_controls, custom_control)
