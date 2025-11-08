extends WhiteboardTool

const BookmarkTool = preload("BookmarkTool.gd")


static var bookmark_icon := IconTexture2D.create("dev.fishies.sunfish.bookmark")
static var unplaced_bookmark_icon := IconTexture2D.create("dev.fishies.sunfish.unplaced_bookmark")
static var view_icon := IconTexture2D.create("view")
static var add_icon := IconTexture2D.create("add")
static var delete_red_icon := IconTexture2D.create("delete_red")


var is_drawing: bool
var preview := BookmarkPreviewElement.new()
var redraw_preview: Callable
var set_wb_xform: Callable
var save_bookmarks: Callable
var inner_container: VBoxContainer
@export_custom(PROPERTY_HINT_EXT_CUSTOM_INSPECTOR, "bookmarks_custom_inspector") var bookmarks: Array[Dictionary]


static func get_id() -> StringName: return "dev.fishies.sunfish.BookmarkTool"


static func get_shortcut() -> InputEvent: return Shortcuts.key(KEY_B | KEY_MASK_SHIFT)


func activated(wb: Whiteboard) -> void:
	if wb.has_tool_data(self):
		bookmarks = wb.get_tool_data(self)
	preview.tool = self
	preview.width = 1.0 / wb.draw_scale
	wb.redraw_preview([preview])
	redraw_preview = wb.redraw_preview
	set_wb_xform = func(xform: Transform2D): wb.draw_xform = xform
	save_bookmarks = func():
		wb.set_tool_data(self, bookmarks)


func receive_input(wb: Whiteboard, event: InputEvent) -> Display:
	var display := Display.new()
	display.preview_elements = [preview]
	preview.width = 1.0 / wb.draw_scale
	var mm := event as InputEventMouseMotion
	if mm:
		preview.position = mm.position
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var name := "%.f, %.f" % [mb.position.x, mb.position.y]
			var bookmark = {
				"name": name,
				"position": mb.position,
				"xform": wb.draw_xform,
			}
			bookmarks.append(bookmark)
			inner_container.add_child(_create_bookmark_delegate(bookmark))
			save_bookmarks.call()
	return display


func bookmarks_custom_inspector() -> Control:
	var control := PanelContainer.new()
	control.custom_minimum_size = Vector2(0, 300)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.theme_type_variation = "AltPanelContainer"
	var scroller := ScrollContainer.new()
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inner_container = VBoxContainer.new()
	inner_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for bookmark in bookmarks:
		inner_container.add_child(_create_bookmark_delegate(bookmark))
	scroller.add_child(inner_container)
	control.add_child(scroller)
	return control


func _create_bookmark_delegate(bookmark: Dictionary) -> Control:
	var container := HBoxContainer.new()
	var line_edit := LineEdit.new()
	line_edit.text = bookmark.name
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.text_changed.connect(func(new_text: String):
		bookmark.name = new_text
		redraw_preview.call()
		save_bookmarks.call()
	)
	var view_button := Button.new()
	view_button.icon = view_icon
	view_button.pressed.connect(func():
		set_wb_xform.call(bookmark.xform)
	)
	var delete_button := Button.new()
	delete_button.icon = delete_red_icon
	delete_button.pressed.connect(func():
		bookmarks.erase(bookmark)
		container.queue_free()
		redraw_preview.call()
		save_bookmarks.call()
	)
	container.add_child(line_edit)
	container.add_child(view_button)
	container.add_child(delete_button)
	return container


class BookmarkPreviewElement extends PlainPreviewElement:
	var tool: BookmarkTool

	func draw(canvas: CanvasItem, wb: Whiteboard) -> void:
		var size := Vector2(BookmarkTool.bookmark_icon.get_size())
		canvas.draw_set_transform_matrix(wb.inv_draw_xform)
		if tool:
			var font := wb.get_theme_default_font()
			var font_size := wb.get_theme_default_font_size()
			for bookmark in tool.bookmarks:
				var bookmark_name: String = bookmark.name
				var bookmark_pos: Vector2 = (wb.draw_xform * bookmark.position).round()
				canvas.draw_texture_rect(BookmarkTool.bookmark_icon, Util.centered_rect2(bookmark_pos, size), false, Color.WHITE)
				var string_size := font.get_string_size(bookmark_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
				canvas.draw_string(font, bookmark_pos + size * Vector2.DOWN + string_size * 0.5 * Vector2.LEFT, bookmark_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, ThemeManager.active_theme.text)
		canvas.draw_texture_rect(BookmarkTool.unplaced_bookmark_icon, Util.centered_rect2((wb.draw_xform * position).round(), size), false, Color.WHITE)
