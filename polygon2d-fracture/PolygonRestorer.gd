class_name PolygonRestorer




var shape_stack : Array = []




func getOriginShape() -> PoolVector2Array:
	if shape_stack.size() <= 0:
		return PoolVector2Array([])
	else:
		return shape_stack.front().shape

func getOriginArea() -> float:
	if shape_stack.size() <= 0:
		return -1.0
	else:
		return shape_stack.front().area





#func _init(_origin_shape : PoolVector2Array, _origin_area : float = -1.0) -> void:
#	addShape(_origin_shape, _origin_area)




func addShape(shape : PoolVector2Array, shape_area : float = -1.0) -> void:
	var entry : Dictionary = createShapeEntry(shape, shape_area)
	shape_stack.push_back(entry)

func popLast() -> Dictionary:
	if shape_stack.size() <= 0:
		return createShapeEntry(PoolVector2Array([]), -1.0, true)
	return shape_stack.pop_back()

func getLast() -> Dictionary:
	if shape_stack.size() <= 0:
		return {}
	else:
		return shape_stack.back()

func createShapeEntry(shape : PoolVector2Array, area : float = -1.0, empty : bool = false) -> Dictionary:
	if area <= 0.0:
		area = PolygonLib.getPolygonArea(shape)
	
	var origin_area : float = getOriginArea()
	var total_p : float = 1.0
	if origin_area > 0.0:
		total_p = area / origin_area
	
	var delta_p : float = 0.0
	if shape_stack.size() > 0:
		delta_p = getLast().total_p - total_p
	
	return {"shape" : shape, "area" : area, "total_p" : total_p, "delta_p" : delta_p, "empty" : empty}
