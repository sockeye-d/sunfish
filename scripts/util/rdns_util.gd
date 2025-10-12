class_name ReverseDNSUtil


static func split(id: String) -> PackedStringArray: return id.split(".")


static func tail(id: String) -> String: return split(id)[-1]


static func path_to_rdns(path: String) -> String: return path.replace("/", ".")


static func id_to_path(id: String) -> String: return id.replace(".", "/")


static func get_resource_id(resource: Resource) -> String:
	return ReverseDNSUtil.path_to_rdns(resource.resource_path.trim_prefix(PluginManager.PLUGIN_PREFIX).get_basename())


static func pretty_print(id: String) -> String:
	return tail(id).capitalize()
