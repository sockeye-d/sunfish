class_name ScrollContainerSpacerComponent extends Node


@export var scroll_container: ScrollContainer
@export var separator: VSeparator


func _ready() -> void:
	scroll_container.get_v_scroll_bar().visibility_changed.connect(func():
		separator.visible = scroll_container.get_v_scroll_bar().is_visible_in_tree()
	)
