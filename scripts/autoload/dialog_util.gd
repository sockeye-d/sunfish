extends Node


func open_file_dialog(filters: PackedStringArray, mode: FileDialog.FileMode, start_path: String = "", start_file: String = "") -> Signal:
	var fd := FileDialog.new()
	var handle := FileDialogHandle.new()
	add_child(fd)
	fd.use_native_dialog = true
	fd.current_dir = Settings["state/last_filedialog_path"] if start_path.is_empty() else start_path
	fd.current_path = fd.current_dir
	if not filters.is_empty() and start_file.is_empty():
		start_file = "file" + filters[0].get_slice(";", 0).get_slice(",", 0).trim_prefix("*")
	fd.current_file = start_file
	fd.file_mode = mode
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.filters = filters
	fd.files_selected.connect(func(selection: PackedStringArray): handle.selected.emit(selection))
	fd.file_selected.connect(func(selection: String): handle.selected.emit([selection]))
	fd.dir_selected.connect(func(selection: String): handle.selected.emit(selection))
	fd.canceled.connect(handle.selected.emit.bind([]))
	fd.popup_centered()
	var cover := Control.new()
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(cover)
	handle.selected.connect(func(paths: PackedStringArray):
		Util.unused(paths)
		Settings["state/last_filedialog_path"] = fd.current_dir
		fd.queue_free()
		cover.queue_free()
	)
	return handle.selected


func open_text_dialog(default_text: String = "", font: Font = null) -> Signal:
	var handle := TextDialogHandle.new()
	var popup := AcceptDialog.new()
	popup.title = "Enter text"
	var le := ConfirmingTextEdit.new()
	if font:
		le.add_theme_font_override("font", font)
	le.text = default_text
	popup.confirmed.connect(func():
		handle.confirmed.emit(le.text)
		popup.queue_free()
	)
	popup.canceled.connect(func():
		handle.confirmed.emit("")
		popup.queue_free()
	)
	le.confirmed.connect(func():
		handle.confirmed.emit(le.text)
		popup.queue_free()
	)
	add_child(popup)
	popup.add_child(le)
	popup.popup_centered(Vector2i(300, 175))
	le.grab_focus.call_deferred(true)
	return handle.confirmed


func open_accept_dialog(inner_control: Control) -> Signal:
	var handle := AcceptDialogHandle.new()
	var popup := ConfirmationDialog.new()
	popup.title = "Enter text"
	popup.confirmed.connect(func():
		handle.closed.emit(true)
		popup.queue_free()
	)
	popup.canceled.connect(func():
		handle.closed.emit(false)
		popup.queue_free()
	)
	add_child(popup)
	popup.add_child(inner_control)
	popup.popup_centered(Vector2i(300, 175))
	return handle.closed


class FileDialogHandle:
	signal selected(files: PackedStringArray)

class TextDialogHandle:
	signal confirmed(text: String)

class AcceptDialogHandle:
	signal closed(accepted: bool)

class ConfirmingTextEdit extends TextEdit:
	signal confirmed
	func _gui_input(event: InputEvent) -> void:
		if event.is_match(Settings["shortcuts/text_accept"]):
			accept_event()
			confirmed.emit()
