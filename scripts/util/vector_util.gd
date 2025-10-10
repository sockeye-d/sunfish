class_name VectorUtil


static func max2(vector: Vector2) -> float:
	return vector[vector.max_axis_index()]


static func max3(vector: Vector3) -> float:
	return vector[vector.max_axis_index()]


static func max2i(vector: Vector2i) -> float:
	return vector[vector.max_axis_index()]


static func max3i(vector: Vector3i) -> float:
	return vector[vector.max_axis_index()]


static func max_mag2(vector: Vector2) -> float:
	return vector[vector.abs().max_axis_index()]


static func max_mag3(vector: Vector3) -> float:
	return vector[vector.abs().max_axis_index()]


static func max_mag2i(vector: Vector2i) -> float:
	return vector[vector.abs().max_axis_index()]


static func max_mag3i(vector: Vector3i) -> float:
	return vector[vector.abs().max_axis_index()]
