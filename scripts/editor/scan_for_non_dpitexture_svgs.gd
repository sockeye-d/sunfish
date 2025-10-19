@tool
extends EditorScript


const SEARCH_PATHS = [
	"res://assets/",
	"res://plugins/",
]


func _run() -> void:
	var errors: PackedStringArray
	for path in SEARCH_PATHS:
		errors.append_array(scan_dir(path))
	#if not errors:
		#print_rich("[color=green]No misimported textures found 👍[/color]")
	#else:
	var window := Window.new()
	var label := RichTextLabel.new()
	if errors:
		for error in errors:
			label.push_bold()
			label.push_meta(error, RichTextLabel.META_UNDERLINE_ON_HOVER)
			label.add_text(error)
			label.pop() # meta
			label.pop() # bold
			label.add_text("\n")
	else:
		label.add_text("No misimported textures found 👍")
	label.meta_clicked.connect(func(meta: String):
		get_editor_interface().get_file_system_dock().navigate_to_path(meta)
	)
	window.add_child(label)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.fit_content = true
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window.size = Vector2i(500, 300)
	window.title = "DPITexture errors"
	window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	get_editor_interface().get_base_control().add_child(window)
	window.show.call_deferred()
	window.close_requested.connect(window.queue_free)


func scan_dir(path: String) -> PackedStringArray:
	var errors: PackedStringArray
	for file in DirAccess.get_files_at(path):
		if file.match("*.svg"):
			var res := load(path.path_join(file))
			if res is not DPITexture:
				#print_rich("[url]%s[/url] is not a DPITexture" % res.resource_path)
				errors.append(res.resource_path)
	for dir in DirAccess.get_directories_at(path):
		errors.append_array(scan_dir(path.path_join(dir)))
	return errors
