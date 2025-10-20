extends MenuButton


static var bug_icon: IconTexture2D:
	get:
		if not bug_icon:
			bug_icon = IconTexture2D.create("bug")
		return bug_icon


enum {
	OPEN = 0,
	SAVE = 1,
	NEW = 2,
	PREFERENCES = 3,
	DEBUG = 5,
}

@onready var debug := $Debug


var last_show_debug_menu: bool = false


func _ready() -> void:
	debug.reparent(get_popup())
	if Settings["core/show_debug_menu"]:
		last_show_debug_menu = true
		_add_debug_menu()
	
	Settings.setting_changed("core/show_debug_menu").connect(func(new_value: bool):
		if new_value and not last_show_debug_menu:
			_add_debug_menu()
		elif last_show_debug_menu:
			_remove_debug_menu()
		last_show_debug_menu = new_value
	)
	
	get_popup().set_item_shortcut(OPEN, Shortcuts.create("shortcuts/open"))
	get_popup().set_item_shortcut(SAVE, Shortcuts.create("shortcuts/save_as"))
	get_popup().set_item_shortcut(NEW, Shortcuts.create("shortcuts/new"))
	get_popup().set_item_shortcut(PREFERENCES, Shortcuts.create("shortcuts/show_preferences"))
	get_popup().id_pressed.connect(func(id: int):
		match id:
			OPEN:
				DataManager.load_file()
			SAVE:
				DataManager.save_file_as()
			NEW:
				DataManager.create_new_file()
			PREFERENCES:
				Settings.show()
	)


func _add_debug_menu() -> void:
	get_popup().add_separator("")
	get_popup().add_icon_item(bug_icon, "Debug")
	get_popup().set_item_submenu_node(DEBUG, debug)


func _remove_debug_menu() -> void:
	get_popup().remove_item(get_popup().item_count - 1)
	get_popup().remove_item(get_popup().item_count - 1)
