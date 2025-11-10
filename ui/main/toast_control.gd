@tool
class_name ToastControl extends Container


@export var toast_severity: ToastManager.Severity
@export_tool_button("Create toast", "Bake") var create_toast := func():
	ToastManager.push_toast(toast_severity, "Hi!")
@export_tool_button("Clear toasts", "Bake") var clear_toasts := func():
	for child in get_children():
		if child.owner == null:
			child.queue_free()
@onready var separation: float = get_theme_constant("separation")

var toast_rect: Rect2
var paused: bool:
	set(value):
		if paused != value:
			for child in get_children():
				child.timer.paused = value
		paused = value
var toast_offset: float:
	set(value):
		toast_offset = value
		queue_sort()
var tween: Tween


func _ready() -> void:
	ToastManager.register_toast_handler(_on_toast_pushed)
	mouse_exited.connect(func(): paused = false)


func _on_toast_pushed(severity: ToastManager.Severity, message: String, additional_controls: Array[Control], custom_control: Control) -> void:
	var toast := Toast.create(severity, message, additional_controls, custom_control)
	toast.timer.paused = paused
	add_child(toast)
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	toast_offset -= toast.size.y + separation
	tween.tween_property(self, "toast_offset", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)


func _process(delta: float) -> void:
	Util.unused(delta)
	paused = is_toast_rect_valid() and toast_rect.has_point(get_local_mouse_position())


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		var toast_width := size.x / 3.0
		var toast_height := 0.0
		for child in get_children():
			var control := child as Toast
			if not control or not control.visible:
				continue
			toast_height = maxf(control.get_combined_minimum_size().y, toast_height)
		var y := size.y - toast_offset
		toast_rect = Rect2(0.0, 0.0, -1.0, -1.0)
		for child in Util.reversed_in_place(get_children()):
			var control := child as Toast
			if not control or not control.visible:
				continue
			y -= toast_height + separation
			var real_toast_width := maxf(toast_width, control.get_combined_minimum_size().x)
			var rect := Rect2(size.x * 0.5 - real_toast_width * 0.5, y, real_toast_width, toast_height)
			toast_rect = toast_rect.merge(rect) if is_toast_rect_valid() else rect
			fit_child_in_rect(control, rect)
	if what == NOTIFICATION_THEME_CHANGED:
		separation = get_theme_constant("separation", "ToastControl")
		queue_sort()
	if what == NOTIFICATION_PREDELETE:
		ToastManager.unregister_toast_handler(_on_toast_pushed)


func is_toast_rect_valid() -> bool: return toast_rect.size.x >= 0.0
