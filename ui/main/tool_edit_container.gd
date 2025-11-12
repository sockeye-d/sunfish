class_name ToolEditContainer extends Container

@onready var inner_container: HBoxContainer = %InnerContainer

@export var tool_container: ToolContainer
var tool_tiles: Dictionary[StringName, ToolTile]
var active_tile_container := ToolEditPane.new()
var available_tile_container := ToolEditPane.new()


func _ready() -> void:
	hide()
	inner_container.add_child(active_tile_container)
	inner_container.add_child(available_tile_container)
	active_tile_container.about_to_drop.connect(available_tile_container.remove_drop_indicator)
	available_tile_container.about_to_drop.connect(active_tile_container.remove_drop_indicator)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PRE_SORT_CHILDREN:
		var width := maxf(
			active_tile_container.get_minimum_size().x,
			available_tile_container.get_minimum_size().x,
		)
		active_tile_container.custom_minimum_size.x = width
		available_tile_container.custom_minimum_size.x = width


func begin_editing() -> void:
	tool_container.hide()
	show()
	for tool_id: StringName in Settings["core/tool_layout"]:
		var tile := ToolTile.new()
		tile.tool_id = tool_id
		tile.container = self
		tool_tiles[tool_id] = tile
		active_tile_container.add_child(tile)
	for tool_id in WhiteboardManager.tools:
		if is_tool_active(tool_id):
			continue
		var tile := ToolTile.new()
		tile.tool_id = tool_id
		tile.container = self
		tool_tiles[tool_id] = tile
		available_tile_container.add_child(tile)


func end_editing() -> void:
	hide()
	tool_container.show()
	active_tile_container.remove_drop_indicator()
	available_tile_container.remove_drop_indicator()
	var ids: Array[StringName]
	for tile: ToolTile in active_tile_container.get_children():
		ids.append(tile.tool_id)
	Settings["core/tool_layout"] = ids
	for tool_id in tool_tiles:
		tool_tiles[tool_id].queue_free()
	tool_tiles.clear()


func is_tool_active(tool_id: StringName) -> bool:
	return tool_id in Settings["core/tool_layout"]


class ToolTile extends PanelContainer:
	var icon: Texture2D
	var tool_id: StringName
	var container: ToolEditContainer

	func _ready() -> void:
		theme_type_variation = "LightPanelContainer"
		icon = IconTexture2D.create(tool_id)
		var icon_display := TextureRect.new()
		icon_display.texture = icon
		add_child(icon_display)

	func _get_drag_data(at_position: Vector2) -> Variant:
		Util.unused(at_position)
		var panel_container := PanelContainer.new()
		var icon_display := TextureRect.new()
		icon_display.texture = icon
		panel_container.add_child(icon_display)
		panel_container.size = size
		set_drag_preview(panel_container)
		var parent := get_parent()
		parent.remove_child(self)
		return ToolDragDropData.new(self, parent, container)

	func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
		return get_parent()._can_drop_data(at_position + position, data)

	func _drop_data(at_position: Vector2, _data: Variant) -> void:
		get_parent()._drop_data(at_position + position, _data)


class ToolEditPane extends VBoxContainer:
	signal about_to_drop
	var drop_index: int
	var drop_indicator := DropIndicator.new()
	func _init() -> void:
		size_flags_vertical = Control.SIZE_EXPAND_FILL

	func remove_drop_indicator() -> void:
		if drop_indicator.get_parent():
			remove_child(drop_indicator)

	func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
		about_to_drop.emit()
		drop_index = calculate_drop_index(at_position)
		if not drop_indicator.get_parent():
			add_child(drop_indicator)
		move_child(drop_indicator, drop_index)
		return data is ToolDragDropData

	func _drop_data(at_position: Vector2, _data: Variant) -> void:
		drop_index = calculate_drop_index(at_position)
		var data := _data as ToolDragDropData
		if data:
			remove_child(drop_indicator)
			add_child(data.tool_tile)
			move_child(data.tool_tile, drop_index)
			data.successfully_dropped = true

	func calculate_drop_index(at_position: Vector2) -> int:
		if get_child_count() == 0:
			return 0
		var mouse_y := at_position.y
		var closest_dist := absf(mouse_y - get_child(0).position.y)
		var closest_index := 0
		for child_index in get_child_count():
			var tile := get_child(child_index) as ToolTile
			if not tile:
				continue
			var tile_y := tile.position.y + tile.size.y
			var dist := absf(tile_y - mouse_y)
			if dist < closest_dist:
				closest_dist = dist
				closest_index = child_index + 1
				if child_index >= drop_indicator.get_index():
					closest_index -= 1
		return closest_index

	class DropIndicator extends HSeparator:
		func _init() -> void:
			theme_type_variation = "DropIndicator"

		func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
			return get_parent()._can_drop_data(at_position + position, data)

		func _drop_data(at_position: Vector2, _data: Variant) -> void:
			get_parent()._drop_data(at_position + position, _data)


class ToolDragDropData:
	var tool_tile: ToolTile
	var container: Node
	var edit_panes: Array[ToolEditPane]
	var successfully_dropped: bool = false

	func _init(_tool_tile: ToolTile, _container: Node, _container_container: ToolEditContainer) -> void:
		tool_tile = _tool_tile
		container = _container
		edit_panes = [
			_container_container.active_tile_container,
			_container_container.available_tile_container,
		]

	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			if not successfully_dropped:
				container.add_child(tool_tile)
			for pane in edit_panes:
				pane.remove_drop_indicator()


func _on_reset_button_pressed() -> void:
	for tool_id in WhiteboardManager.tools:
		var tile := tool_tiles[tool_id]
		tile.reparent(active_tile_container)
		tile.move_to_front()
