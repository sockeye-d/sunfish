class_name Util


const NOTIFICATION_WINDOW_CLOSING = 10000
const ALWAYS_UPPERCASE: PackedStringArray = [
	"ui",
	"gui",
]


static func unused(..._v) -> void:
	pass


static func log10(v: float) -> float: return log(v) / log(10)


static func round_sig_figs(v: float, figures: int) -> float:
	var factor := pow(10.0, figures - ceil(log10(absf(v))))
	return roundf(v * factor) / factor


static func pretty_print_property(property_name: String) -> String:
	if property_name.length() == 0: return ""
	if property_name.length() == 1: return property_name.to_upper()
	property_name = property_name.capitalize().to_lower()
	var first_word := property_name.get_slice(" ", 0)
	var substr_length := 1 if first_word.strip_edges() not in ALWAYS_UPPERCASE else first_word.length()
	return property_name.substr(0, substr_length).to_upper() + property_name.substr(substr_length)


static func default(value, default_value):
	if value:
		return value
	return default_value


static func falloff(x: float) -> float: return maxf(0.0, 2.0 - 1.0 / x if x <= 1.0 else x)


static func get_default_save_path() -> String:
	return "user://%s.sunfish" % Time.get_datetime_string_from_system().replace(":", "_")


static func centered_rect2(center: Vector2, size: Vector2) -> Rect2:
	return Rect2(center - size * 0.5, size)


static func reversed_in_place(array: Array) -> Array:
	array.reverse()
	return array


static func _get_git_shell_arguments(working_dir: String) -> PackedStringArray:
	match OS.get_name():
		"Linux", "macOS", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			return ["sh", "-c", "cd '%s' && git rev-parse HEAD" % working_dir]
		"Windows":
			return ["cmd.exe", "/C", "cd '%s' && git rev-parse HEAD" % working_dir]
		"Android":
			assert(false, "Android is not supported!")
			return []
		"iOS":
			assert(false, "iOS is not supported!")
			return []
		"Web":
			assert(false, "Web is not supported!")
			return []
	return []


static func get_git_hash() -> String:
	var wd := ProjectSettings.globalize_path("res://")
	var output: Array[String] = []
	var args := _get_git_shell_arguments(wd)
	OS.execute(args[0], args.slice(1), output, true)
	return output[0].strip_edges()
