class_name PolygonLib




# MIT License
# -----------------------------------------------------------------------
#                       This file is part of:                           
#                     GODOT Polygon 2D Fracture                         
#           https://github.com/SoloByte/godot-polygon2d-fracture          
# -----------------------------------------------------------------------
# Copyright (c) 2021 David Grueneis
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.




#SUPERSHAPE - SUPERELLIPSE EXAMPLE PARAMETERS
#-------------------------------------------------------------------------------
const SUPER_ELLIPSE_EXAMPLES : Dictionary = {
	"star" : {"a" : 1.0, "b" : 1.0, "n" : 0.5},
	"box" : {"a" : 1.0, "b" : 1.0, "n" : 4.0},
	"diamond" : {"a" : 1.0, "b" : 1.0, "n" : 1.5}
}

const SUPERSHAPE_2D_EXAMPLES : Dictionary = {
	"simple" : {"a" : 1.0, "b" : 1.0, "n1" : 1.0, "n2" : 1.0, "n3" : 1.0, "m_range" : Vector2(1.0, 6.0)},
	"stars" : {"a" : 1.0, "b" : 1.0, "n1" : 0.3, "n2" : 0.3, "n3" : 03, "m_range" : Vector2(1.0, 6.0)},
	"bloated" :  {"a" : 1.0, "b" : 1.0, "n1" : 40.0, "n2" : 10.0, "n3" : 10.0, "m_range" : Vector2(1.0, 6.0)},
	"polygons" :  {"a" : 1.0, "b" : 1.0, "n1" : 800.0, "n2" : 800.0, "n3" : 800.0, "m_range" : Vector2(1.0, 6.0)},
	"asym" :  {"a" : 1.0, "b" : 1.0, "n1" : 60.0, "n2" : 55.0, "n3" : 30.0, "m_range" : Vector2(1.0, 6.0)}
	}

#-------------------------------------------------------------------------------




#CUTTING AND RESTORING
#-------------------------------------------------------------------------------
#cut polygon = cut shape used to cut source polygon
#get_intersect determines if the the intersected area (area shared by both polygons, the area that is cut out of the source polygon) is returned as well
#returns dictionary with final : Array and intersected : Array -> all holes are filtered out already
static func cutShape(source_polygon : PoolVector2Array, cut_polygon : PoolVector2Array, source_trans_global : Transform2D, cut_trans_global : Transform2D) -> Dictionary:
	var cut_pos : Vector2 = toLocal(source_trans_global, cut_trans_global.get_origin())
	
	cut_polygon = rotatePolygon(cut_polygon, cut_trans_global.get_rotation() - source_trans_global.get_rotation())
	cut_polygon = translatePolygon(cut_polygon, cut_pos)
	
	var intersected_polygons : Array = intersectPolygons(source_polygon, cut_polygon, true)
	if intersected_polygons.size() <= 0:
		return {"final" : [], "intersected" : []}
	
	var final_polygons : Array = clipPolygons(source_polygon, cut_polygon, true)
	
	return {"final" : final_polygons, "intersected" : intersected_polygons}


static func restorePolygon(cur_poly : PoolVector2Array, target_poly : PoolVector2Array, amount : float) -> PoolVector2Array:
	var offset_polies : Array = offsetPolygon(cur_poly, amount, true)
	
	var offset_poly : PoolVector2Array
	if offset_polies.size() <= 0:
#		print("MorpPolygon - offset polies size < 0 - target poly returned")
		return target_poly
	elif offset_polies.size() == 1:
#		print("MorpPolygon - offset polies size == 1 - best behaviour")
		offset_poly = offset_polies[0]
	else:
#		print("MorpPolygon - offset polies size > 1 - worst behaviour")
		var biggest_area : float = INF
		var index : int = -1
		
		for i in range(offset_polies.size()):
			var area : float = getPolygonArea(offset_polies[i])
#			print("Check offset polies areas - Index: %d - Area: %f" % [i, area])
			if biggest_area == INF or area > biggest_area:
				biggest_area = area
				index = i
		
		offset_poly = offset_polies[index]
	
	var intersect_polies : Array = intersectPolygons(offset_poly, target_poly, true)
	if intersect_polies.size() <= 0:
#		print("MorpPolygon - intersect polies size < 0 - target poly returned")
		return target_poly
	elif intersect_polies.size() == 1:
#		print("MorpPolygon - intersect polies size == 1 - best behaviour")
		return intersect_polies[0]
	else:
#		print("MorpPolygon - intersect polies size > 1 - worst behaviour")
		var biggest_area : float = INF
		var index : int = -1
		
		for i in range(intersect_polies.size()):
			var area : float = getPolygonArea(intersect_polies[i])
#			print("Check intersect polies areas - Index: %d - Area: %f" % [i, area])
			if biggest_area == INF or area > biggest_area:
				biggest_area = area
				index = i
		
		return intersect_polies[index]

#-------------------------------------------------------------------------------




#TRIANGULATION
#-------------------------------------------------------------------------------
#returns a triangulation dictionary (is used in other funcs parameters)
static func makeTriangles(poly : PoolVector2Array, triangle_points : PoolIntArray, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
	var triangles : Array = []
	var total_area : float = 0.0
	for i in range(triangle_points.size() / 3):
		var index : int = i * 3
		var points : PoolVector2Array = [poly[triangle_points[index]], poly[triangle_points[index + 1]], poly[triangle_points[index + 2]]]
		
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
	var triangle_points : PoolIntArray = Geometry.triangulate_polygon(poly)
	return makeTriangles(poly, triangle_points, with_area, with_centroid)

#triangulates a polygon with the delaunay method and additionally calculates the centroid and area of each triangle alongside the total area of the polygon
static func triangulatePolygonDelaunay(poly : PoolVector2Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
	var total_area : float = 0.0
	var triangle_points = Geometry.triangulate_delaunay_2d(poly)
	return makeTriangles(poly, triangle_points, with_area, with_centroid)
#-------------------------------------------------------------------------------




#UTILITY
#-------------------------------------------------------------------------------
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

#the same as getPolygonCentroid but only takes the source polygon (if you have no triangulation use this)
#if you need triangulation it is better to triangulate the polygon, store the triangulation info and use getPolygonCentroid
#with the generated triangles
static func calculatePolygonCentroid(poly : PoolVector2Array) -> Vector2:
	var triangulation : Dictionary = triangulatePolygon(poly, true, true)
	return getPolygonCentroid(triangulation.triangles, triangulation.area)

#deprecated and not in use anymore (but maybe it is helpful to someone)
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
static func translatePolygon(poly : PoolVector2Array, offset : Vector2) -> PoolVector2Array:
	var new_poly : PoolVector2Array = []
	for p in poly:
		new_poly.append(p + offset)
	return new_poly

#rotates all points of the polygon by rot (in radians)
static func rotatePolygon(poly : PoolVector2Array, rot : float) -> PoolVector2Array:
	var rotated_polygon : PoolVector2Array = []
	
	for p in poly:
		rotated_polygon.append(p.rotated(rot))
	
	return rotated_polygon

#scales all points of a polygon
static func scalePolygon(poly : PoolVector2Array, scale : Vector2) -> PoolVector2Array:
	var scaled_polygon : PoolVector2Array = []
	
	for p in poly:
		scaled_polygon.append(p * scale)
	
	return scaled_polygon 

#calculates the centroid of the polygon and uses it to translate the polygon to Vector2.ZERO
static func centerPolygon(poly : PoolVector2Array) -> PoolVector2Array:
	var centered_polygon : PoolVector2Array = []
	
	var triangulation : Dictionary = triangulatePolygon(poly, true, true)
	var centroid : Vector2 = getPolygonCentroid(triangulation.triangles, triangulation.area)
	
	centered_polygon = translatePolygon(poly, -centroid)
	
	return centered_polygon


static func getTriangleArea(points : PoolVector2Array) -> float:
	var a : float = (points[1] - points[2]).length()
	var b : float = (points[2] - points[0]).length()
	var c : float = (points[0] - points[1]).length()
	var s : float = (a + b + c) * 0.5
	
	var value : float = s * (s - a) * (s - b) * (s - c)
	if value < 0.0:
		return 1.0
	var area : float = sqrt(value)
	return area

#centroid is the center point of a triangle
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

#does the same as Node.toGlobal()
static func toGlobal(global_transform : Transform2D, local_pos : Vector2) -> Vector2:
	return global_transform.xform(local_pos)

#does the same as Node.toLocal()
static func toLocal(global_transform : Transform2D, global_pos : Vector2) -> Vector2:
	return global_transform.affine_inverse().xform(global_pos)

#used to set the texture offset in an texture_info dictionary
static func setTextureOffset(texture_info : Dictionary, centroid : Vector2) -> Dictionary:
	texture_info.offset += centroid.rotated(texture_info.rot)
	return texture_info
#-------------------------------------------------------------------------------




#BOUNDING RECT
#-------------------------------------------------------------------------------
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

#-------------------------------------------------------------------------------




#SHAPE CREATION
#-------------------------------------------------------------------------------
static func createRectanglePolygon(size : Vector2, local_center := Vector2.ZERO) -> PoolVector2Array:
	var rectangle : PoolVector2Array = []
	var extend : Vector2 = size * 0.5
	rectangle.append(local_center - extend)#A
	rectangle.append(local_center + Vector2(extend.x, -extend.y))#B
	rectangle.append(local_center + extend)#C
	rectangle.append(local_center + Vector2(-extend.x, extend.y))#D
	return rectangle

#smooting affects point count -> 0 = 8 Points, 1 = 16, 2 = 32, 3 = 64, 4 = 128, 5 = 256
static func createCirclePolygon(radius : float, smoothing : int = 0, local_center := Vector2.ZERO) -> PoolVector2Array:
	var circle : PoolVector2Array = []
	
	smoothing = clamp(smoothing, 0, 5)
	var point_number : int = pow(2, 3 + smoothing)
	
	var radius_line : Vector2 = Vector2.RIGHT * radius
	var angle_step : float = (PI * 2.0) / point_number as float
	
	for i in range(point_number):
		circle.append(local_center + radius_line.rotated(angle_step * i))
	
	return circle

#creates a beam with a seperate start and end width
static func createBeamPolygon(dir : Vector2, distance : float, start_width : float, end_width : float, start_point_local := Vector2.ZERO) -> PoolVector2Array:
	var beam : PoolVector2Array = []
	if distance == 0: 
		return beam
	
	if start_width <= 0.0 and end_width <= 0.0:
		return beam
	
	if distance < 0:
		dir = -dir
		distance *= -1.0
	
	var end_point : Vector2 = start_point_local + (dir * distance)
	var perpendicular : Vector2 = dir.rotated(PI * 0.5)
	
	if start_width <= 0.0:
		beam.append(start_point_local)
		beam.append(end_point + perpendicular * end_width * 0.5)
		beam.append(end_point - perpendicular * end_width * 0.5)
	elif end_width <= 0.0:
		beam.append(start_point_local + perpendicular * start_width * 0.5)
		beam.append(end_point)
		beam.append(start_point_local - perpendicular * start_width * 0.5)
	else:
		beam.append(start_point_local + perpendicular * start_width * 0.5)
		beam.append(end_point + perpendicular * end_width * 0.5)
		beam.append(end_point - perpendicular * end_width * 0.5)
		beam.append(start_point_local - perpendicular * start_width * 0.5)
	
	return beam


#implemented thanks to Daniel Shiffman´s (@shiffman) coding challenges
#https://thecodingtrain.com/CodingChallenges/019-superellipse.html
#https://en.wikipedia.org/wiki/Superellipse
static func createSuperEllipsePolygon(p_number : int, a : float, b : float, n : float, start_angle_deg : float = 0.0, max_angle_deg : float = 360.0, offset := Vector2.ZERO) -> PoolVector2Array:
	var poly : PoolVector2Array = []
	
	var angle_step_rad : float = (2 * PI) / p_number as float
	var start_angle_rad : float = deg2rad(start_angle_deg)
	var max_angle_rad : float = deg2rad(max_angle_deg)
	var current_angle_rad : float = start_angle_rad
	var na : float = 2.0 / n
	
	while current_angle_rad < start_angle_rad + max_angle_rad:
		var x : float = pow(abs(cos(current_angle_rad)), na) * a * sign(cos(current_angle_rad))
		var y : float = pow(abs(sin(current_angle_rad)), na) * b * sign(sin(current_angle_rad))
		
		poly.append(Vector2(x, y) + offset)
		
		current_angle_rad += angle_step_rad
	return poly

#implemented thanks to Daniel Shiffman´s (@shiffman) coding challenges
#https://thecodingtrain.com/CodingChallenges/023-supershape2d.html
#http://paulbourke.net/geometry/supershape/
static func createSupershape2DPolygon(p_number : int, a : float, b : float, m : float, n1 : float, n2 : float, n3 : float, start_angle_deg : float = 0.0, max_angle_deg : float = 360.0, offset := Vector2.ZERO) -> PoolVector2Array:
	var poly : PoolVector2Array = []
	
	var angle_step_rad : float = (2 * PI) / p_number as float
	var start_angle_rad : float = deg2rad(start_angle_deg)
	var max_angle_rad : float = deg2rad(max_angle_deg)
	var current_angle_rad : float = start_angle_rad
	
	while current_angle_rad < start_angle_rad + max_angle_rad:
		var r : float = calculateSupershape2DRadius(current_angle_rad, a, b, m, n1, n2, n3)
		var x = r * cos(current_angle_rad)
		var y = r * sin(current_angle_rad)
		
		poly.append(Vector2(x, y) + offset)
		
		current_angle_rad += angle_step_rad
	
	return poly


static func calculateSupershape2DRadius(angle_rad : float, a : float, b : float, m : float, n1 : float, n2 : float, n3 : float) -> float:
	var part1 : float = (1.0 / a) * cos((angle_rad * m) / 4.0)
	part1 = abs(part1)
	part1 = pow(part1, n2)
	
	var part2 = (1.0 / b) * sin((angle_rad * m) / 4.0)
	part2 = abs(part2)
	part2 = pow(part2, n3)
	
	var part3 = pow(part1 + part2, 1.0 / n1)
	
	if part3 == 0.0:
		return 1.0
	
	return 1.0 / part3

#-------------------------------------------------------------------------------




#SHAPE INFO
#-------------------------------------------------------------------------------
#just makes a dictionary that can be used in different funcs
static func makeShapeInfo(shape : PoolVector2Array, centered_shape : PoolVector2Array, centroid : Vector2, spawn_pos : Vector2, area : float, source_global_trans : Transform2D) -> Dictionary:
	return {"shape" : shape, "centered_shape" : centered_shape, "centroid" : centroid, "spawn_pos" : spawn_pos, "spawn_rot" : source_global_trans.get_rotation(), "area" : area, "source_global_trans" : source_global_trans}

#makes a shape info with the given parameters
static func getShapeInfo(source_global_trans : Transform2D, source_polygon : PoolVector2Array) -> Dictionary:
	var triangulation : Dictionary = triangulatePolygon(source_polygon, true, true)
	var centroid : Vector2 = getPolygonCentroid(triangulation.triangles, triangulation.area)
	var centered_shape : PoolVector2Array = translatePolygon(source_polygon, -centroid)
	return makeShapeInfo(source_polygon, centered_shape, centroid, getShapeSpawnPos(source_global_trans, centroid), triangulation.area, source_global_trans)

#makes a shape info with the given parameters and has different parameters than getShapeInfo
static func getShapeInfoSimple(source_global_trans : Transform2D, source_polygon : PoolVector2Array, triangulation : Dictionary) -> Dictionary:
	var centroid : Vector2 = getPolygonCentroid(triangulation.triangles, triangulation.area)
	var centered_shape : PoolVector2Array = translatePolygon(source_polygon, -centroid)
	return makeShapeInfo(source_polygon, centered_shape, centroid, getShapeSpawnPos(source_global_trans, centroid), triangulation.area, source_global_trans)

#calculates the global world position for a given centroid
static func getShapeSpawnPos(source_global_trans : Transform2D, centroid : Vector2) -> Vector2:
	var spawn_pos : Vector2 = toGlobal(source_global_trans, centroid)
	return spawn_pos
#-------------------------------------------------------------------------------





#POLYGON OPERATIONS
#-------------------------------------------------------------------------------
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
#-------------------------------------------------------------------------------




#SIMPLIFY LINE
#-------------------------------------------------------------------------------
#my own simplify line code ^^
static func simplifyLine(line : PoolVector2Array, segment_min_length : float = 100.0) -> PoolVector2Array:
	var final_line : PoolVector2Array = [line[0]]

	var i : int = 0
	while i < line.size() - 1:
		var start : Vector2 = line[i]
		var total_dis : float = 0.0
		for j in range(i + 1, line.size()):
			var end : Vector2 = line[j]
			var vec : Vector2 = end - start 
			var dis : float = vec.length()
			var dir : Vector2 = vec.normalized()
			total_dis += dis
			if total_dis > segment_min_length or j >= line.size() - 1:
				final_line.append(end)
				i = j
				break
	
	return final_line

static func simplifyLineRDP(line : PoolVector2Array, epsilon : float = 10.0) -> PoolVector2Array:
	var total : int = line.size()
	var start : Vector2 = line[0]
	var end : Vector2 = line[total - 1]
	
	var rdp_points : Array = [start]
	RDP.calculate(0, total - 1, Array(line), rdp_points, epsilon)
	rdp_points.append(end)
	
	return PoolVector2Array(rdp_points)

#used to simplify a line (less points)
#Ramer-Douglas-Peucker Algorithm (iterative end-point fit algorithm)
class RDP:
	static func calculate(startIndex : int, endIndex : int, line : Array, final_line : Array, epsilon : float) -> void:
		var nextIndex : int = findFurthest(line, startIndex, endIndex, epsilon)
		if nextIndex > 0:
			if startIndex != nextIndex:
				calculate(startIndex, nextIndex, line, final_line, epsilon)
			
			final_line.append(line[nextIndex])
			
			if (endIndex != nextIndex):
				calculate(nextIndex, endIndex, line, final_line, epsilon)

	static func findFurthest(points : Array, a : int, b : int, epsilon : float) -> int:
		var recordDistance : float = -1.0
		var start : Vector2 = points[a]
		var end : Vector2 = points[b]
		var furthestIndex : int = -1
		for i in range(a+1,b):
			var currentPoint : Vector2 = points[i]
			var d : float = lineDist(currentPoint, start, end);
			if d > recordDistance:
				recordDistance = d; 
				furthestIndex = i;
	  
		if recordDistance > epsilon:
			return furthestIndex
		else:
			return -1


	static func lineDist(point : Vector2, line_start : Vector2, line_end : Vector2) -> float:
		var norm = scalarProjection(point, line_start, line_end)
		return (point - norm).length()


	static func scalarProjection(p : Vector2, a : Vector2, b : Vector2) -> Vector2:
		var ap : Vector2 = p - a
		var ab : Vector2 = b - a
		ab = ab.normalized()
		ab *= ap.dot(ab)
		return a + ab

#-------------------------------------------------------------------------------
