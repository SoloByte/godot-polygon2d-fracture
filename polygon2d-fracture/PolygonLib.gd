class_name PolygonLib







#returns a triangulation dictionary (is used in other funcs parameters)
static func makeTriangles(poly : PoolVector2Array, triangle_points : PoolIntArray, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
	var triangles : Array = []
	var total_area : float = 0.0
	for i in range(triangle_points.size() / 3):
		var index : int = i * 3
		var points : Array = [poly[triangle_points[index]], poly[triangle_points[index + 1]], poly[triangle_points[index + 2]]]
		
		var area : float = 0.0
		if with_area:
			area = getTriangleArea(points)
		
		var centroid := Vector2.ZERO
		if with_centroid:
			centroid = getTriangleCentroid(points)
		
		total_area += area
		
		triangles.append(makeTriangle(points, area, centroid))
	return {"triangles" : triangles, "area" : total_area}

#returns a dictionary for triangles
static func makeTriangle(points : PoolVector2Array, area : float, centroid : Vector2) -> Dictionary:
	return {"points" : points, "area" : area, "centroid" : centroid}

#triangulates a polygon and additionally calculates the centroid and area of each triangle alongside the total area of the polygon
static func triangulatePolygon(poly : PoolVector2Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
	var total_area : float = 0.0
	var triangle_points = Geometry.triangulate_polygon(poly)
	return makeTriangles(poly, triangle_points, with_area, with_centroid)

#triangulates a polygon with the delaunay method and additionally calculates the centroid and area of each triangle alongside the total area of the polygon
static func triangulatePolygonDelaunay(poly : PoolVector2Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
	var total_area : float = 0.0
	var triangle_points = Geometry.triangulate_delaunay_2d(poly)
	return makeTriangles(poly, triangle_points, with_area, with_centroid)



#triangulates a polygon and sums the areas of the triangles
static func getPolygonArea(poly : PoolVector2Array) -> float:
	var total_area : float = 0.0
	var triangle_points = Geometry.triangulate_polygon(poly)
	for i in range(triangle_points.size() / 3):
		var index : int = i * 3
		var points : Array = [poly[triangle_points[index]], poly[triangle_points[index + 1]], poly[triangle_points[index + 2]]]
		total_area += getTriangleArea(points)
	return total_area

#triangulates a polygon and sums the weighted centroids of all triangles
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

#moves all points of the polygon by offset
static func translatePolygon(poly : PoolVector2Array, offset : Vector2):
	var new_poly : PoolVector2Array = []
	for p in poly:
		new_poly.append(p + offset)
	return new_poly

#rotates all points of the polygon by rot (in radians)
static func rotatePolygon(poly : PoolVector2Array, rot : float):
	var rotated_polygon : PoolVector2Array = []
	
	for p in poly:
		rotated_polygon.append(p.rotated(rot))
	
	return rotated_polygon



#calculates the bounding rect of a polygon and returns it in form of a Rect2
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

#calculates the furthest distance between to corners (AC) or (BD)
static func getBoundingRectMaxSize(bounding_rect : Rect2) -> float:
	var corners : Dictionary = getBoundingRectCorners(bounding_rect)
	
	var AC : Vector2 = corners.C - corners.C
	var BD : Vector2 = corners.D - corners.B
	
	if AC.length_squared() > BD.length_squared():
		return AC.length()
	else:
		return BD.length() 

#returns a dictionary with the 4 corners of the bounding Rect 
#(TopLeft = A, TopRight = B, BottomRight = C, BottomLeft = D)
static func getBoundingRectCorners(bounding_rect : Rect2) -> Dictionary:
	var A : Vector2 = bounding_rect.position
	var C : Vector2 = bounding_rect.end
	
	var B : Vector2 = Vector2(C.x, A.y)
	var D : Vector2 = Vector2(A.x, C.y)
	return {"A" : A, "B" : B, "C" : C, "D" : D}




static func getTriangleArea(points : PoolVector2Array) -> float:
	var a : float = (points[1] - points[2]).length()
	var b : float = (points[2] - points[0]).length()
	var c : float = (points[0] - points[1]).length()
	var s : float = (a + b + c) * 0.5
	
	return sqrt(s * (s - a) * (s - b) * (s - c))


static func getTriangleCentroid(points : PoolVector2Array) -> Vector2:
	var ab : Vector2 = points[1] - points[0]
	var ac : Vector2 = points[2] - points[0]
	var centroid : Vector2 = points[0] + (ab + ac) / 3.0
	return centroid



#checks all polygons in the array and only returns clockwise polygons (holes)
static func getClockwisePolygons(polygons : Array) -> Array:
	var cw_polygons : Array = []
	for poly in polygons:
		if Geometry.is_polygon_clockwise(poly):
			cw_polygons.append(poly)
	return cw_polygons

#checks all polygons in the array and only returns not clockwise (counter clockwise) polygons (filled polygons)
static func getCounterClockwisePolygons(polygons : Array) -> Array:
	var ccw_polygons : Array = []
	for poly in polygons:
		if not Geometry.is_polygon_clockwise(poly):
			ccw_polygons.append(poly)
	return ccw_polygons



#just a wrapper for the Geometry funcs to filter out holes if wanted----------------------------------------------
static func clipPolygons(poly_a : PoolVector2Array, poly_b : PoolVector2Array, exclude_holes : bool = true) -> Array:
	var new_polygons : Array = Geometry.clip_polygons_2d(poly_a, poly_b)
	if exclude_holes:
		return getCounterClockwisePolygons(new_polygons)
	else:
		return new_polygons


static func excludePolygons(poly_a : PoolVector2Array, poly_b : PoolVector2Array, exclude_holes : bool = true) -> Array:
	var new_polygons : Array = Geometry.exclude_polygons_2d(poly_a, poly_b)
	if exclude_holes:
		return getCounterClockwisePolygons(new_polygons)
	else:
		return new_polygons


static func intersectPolygons(poly_a : PoolVector2Array, poly_b : PoolVector2Array, exclude_holes : bool = true) -> Array:
	var new_polygons : Array = Geometry.intersect_polygons_2d(poly_a, poly_b)
	if exclude_holes:
		return getCounterClockwisePolygons(new_polygons)
	else:
		return new_polygons


static func mergePolygons(poly_a : PoolVector2Array, poly_b : PoolVector2Array, exclude_holes : bool = true) -> Array:
	var new_polygons : Array = Geometry.merge_polygons_2d(poly_a, poly_b)
	if exclude_holes:
		return getCounterClockwisePolygons(new_polygons)
	else:
		return new_polygons


static func offsetPolyline(line : PoolVector2Array, delta : float, exclude_holes : bool = true) -> Array:
	var new_polygons : Array = Geometry.offset_polyline_2d(line, delta)
	if exclude_holes:
		return getCounterClockwisePolygons(new_polygons)
	else:
		return new_polygons


static func offsetPolygon(poly : PoolVector2Array, delta : float, exclude_holes : bool = true) -> Array:
	var new_polygons : Array = Geometry.offset_polygon_2d(poly, delta)
	if exclude_holes:
		return getCounterClockwisePolygons(new_polygons)
	else:
		return new_polygons
#-----------------------------------------------------------------------------------------------------------------
