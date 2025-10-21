extends MenuButton


static var bug_icon: IconTexture2D:
	get:
		if not bug_icon:
			bug_icon = IconTexture2D.create("bug")
		return bug_icon


enum {
	FILE_SPACER,
	FILE_OPEN,
	FILE_SAVE,
	FILE_NEW,
	PREFERENCES,
	VIEW_SPACER,
	RESET_ZOOM,
	RESET_VIEW,
}

var debug_spacer_id: int = -1
var debug_id: int = -1

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
	
	get_popup().set_item_shortcut(FILE_OPEN, Shortcuts.create("shortcuts/open"))
	get_popup().set_item_shortcut(FILE_SAVE, Shortcuts.create("shortcuts/save_as"))
	get_popup().set_item_shortcut(FILE_NEW, Shortcuts.create("shortcuts/new"))
	get_popup().set_item_shortcut(PREFERENCES, Shortcuts.create("shortcuts/show_preferences"))
	get_popup().set_item_shortcut(RESET_ZOOM, Shortcuts.create("shortcuts/reset_zoom"))
	get_popup().set_item_shortcut(RESET_VIEW, Shortcuts.create("shortcuts/reset_view"))
	get_popup().id_pressed.connect(func(id: int):
		match id:
			FILE_OPEN:
				DataManager.load_file()
			FILE_SAVE:
				DataManager.save_file_as()
			FILE_NEW:
				DataManager.create_new_file()
			PREFERENCES:
				Settings.show()
	)


func _add_debug_menu() -> void:
	debug_spacer_id = get_popup().item_count
	get_popup().add_separator("")
	debug_id = get_popup().item_count
	get_popup().add_icon_item(bug_icon, "Debug")
	get_popup().set_item_submenu_node(debug_id, debug)


func _remove_debug_menu() -> void:
	get_popup().remove_item(get_popup().item_count - 1)
	get_popup().remove_item(get_popup().item_count - 1)
