extends MenuButton


func _ready() -> void:
	for item_index in item_count:
		var item_text := get_popup().get_item_text(item_index)
		var node := get_node_or_null(item_text)
		if node:
			node.reparent(get_popup())
			get_popup().set_item_submenu_node(item_index, node)
	
	get_popup().id_pressed.connect(func(id: int):
		match id:
			4:
				Settings.show()
	)
