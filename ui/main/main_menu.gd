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
	EDIT_SPACER,
	EDIT_UNDO,
	VIEW_SPACER,
	VIEW_RESET_ZOOM,
	VIEW_RESET_VIEW,
	OTHER_SPACER,
	OTHER_PREFERENCES,
	OTHER_PLUGINS,
}

var debug_spacer_id: int = -1
var debug_id: int = -1

@onready var debug := $Debug


var last_show_debug_menu: bool = false


func _ready() -> void:
	add_separator("File")
	var open := add_item("Open", "open", "shortcuts/open")
	var save := add_item("Save as", "save", "shortcuts/save_as")
	var new := add_item("New", "new", "shortcuts/new")
	add_separator("Edit")
	var undo := add_item("Undo", "save", "shortcuts/undo")
	var preferences := add_item("Preferences", "config", "shortcuts/show_preferences")
	var shortcuts := add_item("Shortcuts", "config", "shortcuts/show_shortcuts")
	var plugins := add_item("Plugins", "plugins", "shortcuts/show_plugins")
	add_separator("View")
	var reset_zoom := add_item("Reset zoom", "reset_zoom", "shortcuts/reset_zoom")
	var reset_view := add_item("Reset view", "reset_view", "shortcuts/reset_view")

	get_popup().index_pressed.connect(func(index: int):
		match index:
			open:
				WhiteboardBus.load_file()
			save:
				WhiteboardBus.save_file_as()
			new:
				WhiteboardBus.create_new_file()
			undo:
				WhiteboardBus.undo.emit()
			reset_zoom:
				WhiteboardBus.view_reset_zoom.emit()
			reset_view:
				WhiteboardBus.view_reset_view.emit()
			preferences:
				Settings.show_settings()
			shortcuts:
				Settings.show_shortcuts()
			plugins:
				pass
	)

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


func _add_debug_menu() -> void:
	debug_spacer_id = get_popup().item_count
	get_popup().add_separator("")
	debug_id = get_popup().item_count
	get_popup().add_icon_item(bug_icon, "Debug")
	get_popup().set_item_submenu_node(debug_id, debug)


func _remove_debug_menu() -> void:
	get_popup().remove_item(get_popup().item_count - 1)
	get_popup().remove_item(get_popup().item_count - 1)


func add_item(item_text: String, item_icon_name: String, item_shortcut_id: String) -> int:
	get_popup().add_icon_item(IconTexture2D.create(item_icon_name), item_text)
	get_popup().set_item_shortcut(item_count - 1, Shortcuts.create(item_shortcut_id))
	return item_count - 1


func add_separator(label: String = "") -> void:
	get_popup().add_separator(label)
