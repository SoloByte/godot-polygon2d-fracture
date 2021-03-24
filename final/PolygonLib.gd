class_name PolygonLib











static func triangulatePolygon(poly : PoolVector2Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
	var total_area : float = 0.0
	var triangle_points = Geometry.triangulate_polygon(poly)
	var triangulation : Dictionary = {"triangles" : [], "area" : 0.0}
	for i in range(triangle_points.size() / 3):
		var index : int = i * 3
		var points : Array = [poly[triangle_points[index]], poly[triangle_points[index + 1]], poly[triangle_points[index + 2]]]
		var area : float = 0.0
		
		if with_area:
			area = getTriangleArea(points)
		var centroid := Vector2.ZERO
		
		if with_centroid:
			centroid = getTriangleCentroid(points)
		
		var triangle : Dictionary = {"points" : points, "area" : area, "centroid" : centroid}
		total_area += area
		triangulation.triangles.append(triangle)
		
	triangulation.area = total_area
	return triangulation


static func triangulatePolygonDelauny(poly : PoolVector2Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
	var total_area : float = 0.0
	var triangle_points = Geometry.triangulate_delaunay_2d(poly)
	var triangulation : Dictionary = {"triangles" : [], "area" : 0.0}
	for i in range(triangle_points.size() / 3):
		var index : int = i * 3
		var points : PoolVector2Array = [poly[triangle_points[index]], poly[triangle_points[index + 1]], poly[triangle_points[index + 2]]]
		var area : float = 0.0
		
		if with_area:
			area = getTriangleArea(points)
		var centroid := Vector2.ZERO
		
		if with_centroid:
			centroid = getTriangleCentroid(points)
		
		var triangle : Dictionary = {"points" : points, "area" : area, "centroid" : centroid}
		total_area += area
		triangulation.triangles.append(triangle)
		
	triangulation.area = total_area
	return triangulation




static func getPolygonArea(poly : PoolVector2Array) -> float:
	var triangulation : Dictionary = triangulatePolygon(poly, true, false)
	return triangulation.area


static func getPolygonCentroid(triangles : Array, total_area : float) -> Vector2:
	var weighted_centroid := Vector2.ZERO
	for triangle in triangles:
		weighted_centroid += (triangle.centroid * triangle.area)
	return weighted_centroid / total_area


static func getPolygonVisualCenterPoint(poly : PoolVector2Array) -> Vector2:
	var center_points : Array = []
	
	for i in range(poly.size() - 1):
		var p : Vector2 = lerp(poly[i], poly[i+1], 0.5)
		center_points.append(p)
	
	var total := Vector2.ZERO
	for p in center_points:
		total += p
	
	total /= center_points.size()
	
	return total


static func translatePolygon(poly : PoolVector2Array, offset : Vector2):
	var new_poly : PoolVector2Array = []
	for p in poly:
		new_poly.append(p + offset)
	return new_poly


static func rotatePolygon(poly : PoolVector2Array, rot : float):
	var rotated_polygon : PoolVector2Array = []
	
	for p in poly:
		rotated_polygon.append(p.rotated(rot))
	
	return rotated_polygon




static func getBoundingRect(poly : PoolVector2Array) -> Rect2:
	var start := Vector2.ZERO
	var end := Vector2.ZERO
	
	for point in poly:
		if point.x < start.x:
			start.x = point.x
		elif point.x > end.x:
			end.x = point.x
		
		if point.y < start.y:
			start.y = point.y
		elif point.y > end.y:
			end.y = point.y
	
	return Rect2(start, end - start)


static func getBoundingRectMaxSize(bounding_rect : Rect2) -> float:
	var corners : Dictionary = getBoundingRectCorners(bounding_rect)
	
	var AC : Vector2 = corners.C - corners.C
	var BD : Vector2 = corners.D - corners.B
	
	if AC.length_squared() > BD.length_squared():
		return AC.length()
	else:
		return BD.length() 


static func getBoundingRectCorners(bounding_rect : Rect2) -> Dictionary:
	var A : Vector2 = bounding_rect.position
	var C : Vector2 = bounding_rect.end
	
	var B : Vector2 = Vector2(C.x, A.y)
	var D : Vector2 = Vector2(A.x, C.y)
	return {"A" : A, "B" : B, "C" : C, "D" : D}











#func getCutLinesFromPoints(points : Array, cuts : int, max_size : float) -> Array:
#	var cut_lines : Array = []
#	if cuts <= 0 or not points or points.size() <= 2: return cut_lines
#
#	for i in range(cuts):
#		var point_pool : Array = points.duplicate(false)
#		var index : int = _rng.randi_range(0, point_pool.size() - 1)
#		var start : Vector2 = point_pool[index]
#		point_pool.remove(index)
#
#		index = _rng.randi_range(0, point_pool.size() - 1)
#		var end : Vector2 = point_pool[index]
#
#		var dir : Vector2 = (end - start).normalized()
#
#		#extend the line so it will always be bigger than the polygon
#		start -= dir * max_size
#		end += dir * max_size
#
#		var line : Rect2 = Rect2(start, end - start)
#		cut_lines.append(line)
#	return cut_lines
#
#
#func getCutLines(bounding_rect : Rect2, number : int) -> Array:
#	var corners : Dictionary = getBoundingRectCorners(bounding_rect)
#
#	var horizontal_pair : Dictionary = {"left" : [corners.A, corners.D], "right" : [corners.B, corners.C]}
#	var vertical_pair : Dictionary = {"top" : [corners.A, corners.B], "bottom" : [corners.D, corners.C]}
#
#	var lines : Array = []
#	for i in range(number):
#
#		if _rng.randf() < 0.5:#horizontal
#			var start : Vector2 = lerp(horizontal_pair.left[0], horizontal_pair.left[1], _rng.randf())
#			var end : Vector2 = lerp(horizontal_pair.right[0], horizontal_pair.right[1], _rng.randf())
#			var line : Rect2 = Rect2(start, end - start)
#			lines.append(line)
#		else:#vertical
#			var start : Vector2 = lerp(vertical_pair.top[0], vertical_pair.top[1], _rng.randf())
#			var end : Vector2 = lerp(vertical_pair.bottom[0], vertical_pair.bottom[1], _rng.randf())
#			var line : Rect2 = Rect2(start, end - start)
#			lines.append(line)
#
#	return lines


#func getRandomPointsInRectangle(rectangle : Rect2, number : int) -> PoolVector2Array:
#	var points : PoolVector2Array = []
#
#	for i in range(number):
#		var x : float = _rng.randf_range(rectangle.position.x, rectangle.end.x)
#		var y : float = _rng.randf_range(rectangle.position.y, rectangle.end.y)
#		points.append(Vector2(x, y))
#
#	return points


#func getRandomPointsInPolygon(poly : PoolVector2Array, number : int) -> PoolVector2Array:
#	var triangulation : Dictionary = triangulatePolygon(poly, true, false)
#
#	var points : PoolVector2Array = []
#
#	for i in range(number):
#		var triangle : Array = getRandomTriangle(triangulation)
#		if triangle.size() <= 0: continue
#		var point : Vector2 = getRandomPointInTriangle(triangle)
#		points.append(point)
#
#	return points
#
#
#func getRandomTriangle(triangulation : Dictionary) -> Array:
#	var chosen_weight : float = _rng.randf() * triangulation.area
#	var current_weight : float = 0.0
#	for triangle in triangulation.triangles:
#		current_weight += triangle.area
#		if current_weight > chosen_weight:
#			return triangle.points
#	return []
#
#
#func getRandomPointInTriangle(points : PoolVector2Array) -> Vector2:
#	var rand_1 : float = _rng.randf()
#	var rand_2 : float = _rng.randf()
#	var sqrt_1 : float = sqrt(rand_1)
#
#	return (1.0 - sqrt_1) * points[0] + sqrt_1 * (1.0 - rand_2) * points[1] + sqrt_1 * rand_2 * points[2]












