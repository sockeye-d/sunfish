extends Configuration


static func _static_init() -> void:
	PluginManager.register_configuration(new())


@warning_ignore_start("int_as_enum_without_cast", "int_as_enum_without_match")
@export var open := Shortcuts.key(KEY_O, KEY_MASK_CTRL)
@export var save_as := Shortcuts.key(KEY_S, KEY_MASK_CTRL)
@export var new := Shortcuts.key(KEY_N, KEY_MASK_CTRL)
@export var show_preferences := Shortcuts.key(KEY_COMMA, KEY_MASK_CTRL | KEY_MASK_SHIFT)

@export var text_accept := Shortcuts.key(KEY_ENTER, KEY_MASK_CTRL)

func get_id() -> String: return "shortcuts"
