class_name Util


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
	return property_name.substr(0, 1).to_upper() + property_name.substr(1)


static func default(value, default_value):
	if value:
		return value
	return default_value
