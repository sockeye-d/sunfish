extends Node


signal orientation_changed(new_orientation: Orientation)


func _ready() -> void:
	get_tree().root.size_changed.connect(_update)


func _update() -> void:
	var window_size := get_tree().root.size
	orientation_changed.emit(HORIZONTAL if window_size.x > window_size.y else VERTICAL)
