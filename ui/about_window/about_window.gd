@tool
extends Window

const AppInfo = preload("uid://dfevfke0ys3j3")

@onready var version_label: Label = %VersionLabel
@onready var license_label: RichTextLabel = %License
@onready var godot_license_label: RichTextLabel = %"Godot (MIT)"
@onready var other: RichTextLabel = %Other

@warning_ignore("unused_private_class_variable")
@export_tool_button("Update text", "Reload") var __ := _update_text

func _ready() -> void:
	close_requested.connect(hide)
	_update_text()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()


func _update_text() -> void:
	version_label.text = "sunfish v%s" % AppInfo.VERSION
	license_label.text = AppInfo.LICENSE
	godot_license_label.text = Engine.get_license_text()

	var licenses := Engine.get_license_info()
	other.clear()
	for license_id: String in licenses:
		var license: String = licenses[license_id]
		other.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		other.push_bold()
		other.add_text(license_id + "\n")
		other.pop()
		other.pop()
		other.add_text(license)
