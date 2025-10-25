@abstract
class_name Configuration extends Resource

enum Location {
	CONFIG,
	LOCAL,
}


@abstract func get_id() -> StringName


func get_location() -> Location: return Location.CONFIG
