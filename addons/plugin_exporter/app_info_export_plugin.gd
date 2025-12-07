class_name AppInfoExportPlugin extends EditorExportPlugin


const AppInfo = preload("uid://dfevfke0ys3j3")


func _get_name() -> String: return "AppInfoExportPlugin"


func _begin_customize_resources(platform: EditorExportPlatform, features: PackedStringArray) -> bool:
	return true


func _get_customization_configuration_hash() -> int:
	return randi()


func _customize_resource(resource: Resource, path: String) -> Resource:
	if path == "res://app_info.tres" and resource is AppInfoContainer:
		resource.git_hash = resource.git_hash
		return resource
	return null
