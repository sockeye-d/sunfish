extends MenuButton

enum {
	OPEN = 0,
	SAVE = 1,
	NEW = 2,
	PREFERENCES = 3,
	DEBUG = 4,
}


func _ready() -> void:
	for item_index in item_count:
		var item_text := get_popup().get_item_text(item_index)
		var node := get_node_or_null(item_text)
		if node:
			node.reparent(get_popup())
			get_popup().set_item_submenu_node(item_index, node)
	
	get_popup().set_item_shortcut(OPEN, Shortcuts.create("open"))
	get_popup().set_item_shortcut(SAVE, Shortcuts.create("save"))
	get_popup().set_item_shortcut(PREFERENCES, Shortcuts.create("show_preferences"))
	get_popup().id_pressed.connect(func(id: int):
		match id:
			OPEN:
				DataManager.load_file()
			SAVE:
				DataManager.save_file()
			NEW:
				DataManager.create_new_file()
			PREFERENCES:
				Settings.show()
	)
