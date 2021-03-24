class_name Line




var start := Vector2.ZERO
var end := Vector2.ZERO

var start_end := Vector2.ZERO

var dir := Vector2.ZERO

var length : float = -1.0
var length_squared : float = -1.0




func _init(start : Vector2, end : Vector2) -> void:
	self.start = start
	self.end = end




func getStartEndVector() -> Vector2:
	if start_end == Vector2.ZERO:
		start_end = end - start
	return start_end

func getDir() -> Vector2:
	if dir == Vector2.ZERO:
		dir = getStartEndVector().normalized()
	return dir

func getLength() -> float:
	if length < 0:
		length = getStartEndVector().length()
	return length

func getLengthSquared() -> float:
	if length_squared < 0.0:
		length_squared = getStartEndVector().length_squared()
	return length_squared
