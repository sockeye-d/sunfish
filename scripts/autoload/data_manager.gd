extends Node


signal file_load(filepath: String)
signal file_save(filepath: String)
signal file_new


func _ready() -> void:
	Settings.setting_changed("state/last_opened_filepath").connect(func(v):
		Util.unused(v)
		update_window_title()
	)
	update_window_title() 


func load_file() -> void:
	var filepath: PackedStringArray = await DialogUtil.open_file_dialog(
		["*.sunfish;Sunfish files"],
		FileDialog.FILE_MODE_OPEN_FILE,
		Settings["state/last_opened_filepath"]
	)
	if filepath.is_empty():
		return
	Settings["state/last_opened_filepath"] = filepath[0]
	update_window_title()
	file_load.emit(filepath[0])


func save_file_as() -> void:
	var filepath: PackedStringArray = await DialogUtil.open_file_dialog(
		["*.sunfish;Sunfish files"],
		FileDialog.FILE_MODE_SAVE_FILE,
		Settings["state/last_opened_filepath"]
	)
	if filepath.is_empty():
		return
	Settings["state/last_opened_filepath"] = filepath[0]
	update_window_title()
	file_save.emit(filepath[0])


func create_new_file() -> void:
	Settings["state/last_opened_filepath"] = ""
	file_new.emit()


func get_default_save_path() -> String:
	return "user://%s.sunfish" % Time.get_datetime_string_from_system().replace(":", "_")


func update_window_title() -> void:
	get_tree().root.title = "sunfish - %s" % (Settings["state/last_opened_filepath"] as String).get_file()
