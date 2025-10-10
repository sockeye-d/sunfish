class_name Util


static func unused(v) -> void:
	v = v


static func log10(v: float) -> float: return log(v) / log(10)


static func round_sig_figs(v: float, figures: int) -> float:
	var factor := pow(10.0, figures - ceil(log10(absf(v))))
	return roundf(v * factor) / factor
