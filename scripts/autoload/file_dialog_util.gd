extends Node


func open_file_dialog(filters: PackedStringArray, mode: FileDialog.FileMode) -> FileDialogHandle:
	var fd := FileDialog.new()
	var handle := FileDialogHandle.new()
	add_child(fd)
	fd.use_native_dialog = true
	fd.file_mode = mode
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.filters = filters
	fd.files_selected.connect(func(selection: PackedStringArray): handle.selected.emit(selection))
	fd.file_selected.connect(func(selection: String): handle.selected.emit([selection]))
	fd.dir_selected.connect(func(selection: String): handle.selected.emit(selection))
	fd.canceled.connect(handle.selected.emit.bind([]))
	fd.popup_centered()
	return handle


class FileDialogHandle:
	signal selected(files: PackedStringArray)
