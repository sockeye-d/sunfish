extends Node


signal file_loaded(filepath: String)
signal file_save
signal new_file


func load_file() -> void:
	var filepath: PackedStringArray = await DialogUtil.open_file_dialog(["*.sunfish;Sunfish files"], FileDialog.FILE_MODE_OPEN_FILE)
	if filepath.is_empty():
		return
	Settings["state/last_opened_filepath"] = filepath[0]
	file_loaded.emit(filepath[0])


func save_file() -> void:
	file_save.emit()


func create_new_file() -> void:
	Settings["state/last_opened_filepath"] = ""
	new_file.emit()
