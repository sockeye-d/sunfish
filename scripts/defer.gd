class_name Defer extends RefCounted


var _callback: Callable


func _init(callback: Callable) -> void:
	_callback = callback


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_callback.call()
