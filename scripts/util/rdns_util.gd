class_name ReverseDNSUtil


static func split(id: String) -> PackedStringArray: return id.split(".")


static func tail(id: String) -> String: return split(id)[-1]
