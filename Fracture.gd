extends Node2D




export(Color) var fracture_body_color
export(PackedScene) var fracture_body_template
export(bool) var delauny_fractrue = false
export(bool) var simple_fracture = true
export(int) var random_points : int = 10
export(int) var cuts : int = 3
export(int) var min_area : int = 25



onready var _source_polygon_parent := $SourcePolygons
onready var _parent := $Parent
onready var _rng := RandomNumberGenerator.new()




func _ready() -> void:
	_rng.randomize()
	update()





func fractureSimple(source_polygon : PoolVector2Array, world_pos : Vector2, cut_number : int, min_discard_area : float) -> void:
	var bounding_rect : Rect2 = getBoundingRect(source_polygon)
	var cut_lines : Array = getCutLines(bounding_rect, cut_number)
	
	var polygons : Array = [source_polygon]
	
	for line in cut_lines:
		var poly_line = Geometry.offset_polyline_2d(makeLine(line), 0.1)[0]
		var new_polies : Array = []
		for poly in polygons:
			var result : Array = Geometry.clip_polygons_2d(poly, poly_line)
			new_polies += result
		
		polygons.clear()
		polygons += new_polies
	
	
	for poly in polygons:
		if not Geometry.is_polygon_clockwise(poly):
			var triangulation : Dictionary = triangulatePolygon(poly, true, true)
			
			if triangulation.area > min_discard_area:
				spawnFractureBody(poly, getPolyCentroid(triangulation.triangles, triangulation.area), world_pos)


func fracture(source_polygon : PoolVector2Array, world_pos : Vector2, cut_number : int, point_number : int, min_discard_area : float) -> void:
	var bounding_rect : Rect2 = getBoundingRect(source_polygon)
	var points : Array = getRandomPointsInPolygon(source_polygon, point_number)
	var cut_lines : Array = getCutLinesFromPoints(points, cut_number, getBoundingRectMaxSize(bounding_rect))
	
	var polygons : Array = [source_polygon]
	
	for line in cut_lines:
		var poly_line = Geometry.offset_polyline_2d(makeLine(line), 0.1)[0]
		var new_polies : Array = []
		for poly in polygons:
			var result : Array = Geometry.clip_polygons_2d(poly, poly_line)
			new_polies += result
		
		polygons.clear()
		polygons += new_polies
	
	
	for poly in polygons:
		if not Geometry.is_polygon_clockwise(poly):
			var triangulation : Dictionary = triangulatePolygon(poly, true, true)
			
			if triangulation.area > min_discard_area:
				spawnFractureBody(poly, getPolyCentroid(triangulation.triangles, triangulation.area), world_pos)


func fractureDelauny(source_polygon : PoolVector2Array, world_pos : Vector2, fracture_number : int, min_discard_area : float) -> void:
	var points = getRandomPointsInPolygon(source_polygon, fracture_number)
	var triangulation : Dictionary = triangulatePolygonDelauny(points + source_polygon, true, true)
	
	for triangle in triangulation.triangles:
		if triangle.area < min_discard_area:
			continue
		
		var is_inside_poly : bool = true
		for p in triangle.points:
			if not Geometry.is_point_in_polygon(p, source_polygon):
				is_inside_poly = false
				break
		
		if is_inside_poly:
			spawnFractureBody(triangle.points, triangle.centroid, world_pos)
		else:
			var results : Array = Geometry.intersect_polygons_2d(triangle.points, source_polygon)
			for r in results:
				if r.size() > 0 and not Geometry.is_polygon_clockwise(r):
					if r.size() == 3:
						var area : float = getTriangleArea(r)
						if area >= min_discard_area:
							spawnFractureBody(r, getTriangleCentroid(r), world_pos)
					else:
						var t : Dictionary = triangulatePolygon(r, true, true)
						if t.area >= min_discard_area:
							spawnFractureBody(r, getPolyCentroid(t.triangles, t.area), world_pos)


func triangulatePolygon(poly : PoolVector2Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
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


func triangulatePolygonDelauny(poly : PoolVector2Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
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


func getPolygonArea(poly : PoolVector2Array) -> float:
	var triangulation : Dictionary = triangulatePolygon(poly, true, false)
	return triangulation.area


func getTriangleArea(points : PoolVector2Array) -> float:
	var a : float = (points[1] - points[2]).length()
	var b : float = (points[2] - points[0]).length()
	var c : float = (points[0] - points[1]).length()
	var s : float = (a + b + c) * 0.5
	
	return sqrt(s * (s - a) * (s - b) * (s - c))


func getTriangleCentroid(points : PoolVector2Array) -> Vector2:
	var ab : Vector2 = points[1] - points[0]
	var ac : Vector2 = points[2] - points[0]
	var centroid : Vector2 = points[0] + (ab + ac) / 3.0
	return centroid


func getPolyCentroid(triangles : Array, total_area : float) -> Vector2:
	var weighted_centroid := Vector2.ZERO
	for triangle in triangles:
		weighted_centroid += (triangle.centroid * triangle.area)
	return weighted_centroid / total_area


func getPolyVisualCenterPoint(poly : PoolVector2Array) -> Vector2:
	var center_points : Array = []
	
	for i in range(poly.size() - 1):
		var p : Vector2 = lerp(poly[i], poly[i+1], 0.5)
		center_points.append(p)
	
	var total := Vector2.ZERO
	for p in center_points:
		total += p
	
	total /= center_points.size()
	
	return total


func translatePolygon(poly : PoolVector2Array, offset : Vector2):
	var new_poly : PoolVector2Array = []
	for p in poly:
		new_poly.append(p + offset)
	return new_poly


func spawnFractureBody(poly : PoolVector2Array, center_point : Vector2, world_pos : Vector2) -> void:
	var instance = fracture_body_template.instance()
	_parent.add_child(instance)
#	print("center point: ", center_point)
#	var center_point : Vector2 = getPolyCenterPoint(poly)
	instance.global_position = to_global(center_point) + world_pos
	
	poly = translatePolygon(poly, -center_point)
	
	instance.setPolygon(poly)
	instance.setColor(fracture_body_color)
	var dir : Vector2 = (to_global(center_point) - global_position).normalized()
	instance.apply_central_impulse(dir * _rng.randf_range(125, 175))
	instance.angular_velocity = _rng.randf_range(-1, 1)


func getBoundingRectMaxSize(bounding_rect : Rect2) -> float:
	var corners : Dictionary = getBoundingRectCorners(bounding_rect)
	
	var AC : Vector2 = corners.C - corners.C
	var BD : Vector2 = corners.D - corners.B
	
	if AC.length_squared() > BD.length_squared():
		return AC.length()
	else:
		return BD.length() 


func getBoundingRectCorners(bounding_rect : Rect2) -> Dictionary:
	var A : Vector2 = bounding_rect.position
	var C : Vector2 = bounding_rect.end
	
	var B : Vector2 = Vector2(C.x, A.y)
	var D : Vector2 = Vector2(A.x, C.y)
	return {"A" : A, "B" : B, "C" : C, "D" : D}


func getCutLinesFromPoints(points : Array, cuts : int, max_size : float) -> Array:
	var cut_lines : Array = []
	if cuts <= 0 or not points or points.size() <= 2: return cut_lines
	
	for i in range(cuts):
		var point_pool : Array = points.duplicate(false)
		var index : int = _rng.randi_range(0, point_pool.size() - 1)
		var start : Vector2 = point_pool[index]
		point_pool.remove(index)
		
		index = _rng.randi_range(0, point_pool.size() - 1)
		var end : Vector2 = point_pool[index]
		
		var dir : Vector2 = (end - start).normalized()
		
		#extend the line so it will always be bigger than the polygon
		start -= dir * max_size
		end += dir * max_size
		
		var line : Rect2 = Rect2(start, end - start)
		cut_lines.append(line)
	return cut_lines


func getCutLines(bounding_rect : Rect2, number : int) -> Array:
	var corners : Dictionary = getBoundingRectCorners(bounding_rect)
	
	var horizontal_pair : Dictionary = {"left" : [corners.A, corners.D], "right" : [corners.B, corners.C]}
	var vertical_pair : Dictionary = {"top" : [corners.A, corners.B], "bottom" : [corners.D, corners.C]}
	
	var lines : Array = []
	for i in range(number):
		
		if _rng.randf() < 0.5:#horizontal
			var start : Vector2 = lerp(horizontal_pair.left[0], horizontal_pair.left[1], _rng.randf())
			var end : Vector2 = lerp(horizontal_pair.right[0], horizontal_pair.right[1], _rng.randf())
			var line : Rect2 = Rect2(start, end - start)
			lines.append(line)
		else:#vertical
			var start : Vector2 = lerp(vertical_pair.top[0], vertical_pair.top[1], _rng.randf())
			var end : Vector2 = lerp(vertical_pair.bottom[0], vertical_pair.bottom[1], _rng.randf())
			var line : Rect2 = Rect2(start, end - start)
			lines.append(line)
	
	return lines


func makeLine(rect : Rect2) -> PoolVector2Array:
	var line : PoolVector2Array = []
	line.append(rect.position)
	line.append(rect.end)
	return line


func getBoundingRect(poly : PoolVector2Array) -> Rect2:
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


func getRandomPointsInPolygon(poly : PoolVector2Array, number : int) -> PoolVector2Array:
	var triangulation : Dictionary = triangulatePolygon(poly, true, false)
	
	var points : PoolVector2Array = []
	
	for i in range(number):
		var triangle : Array = getRandomTriangle(triangulation)
		if triangle.size() <= 0: continue
		var point : Vector2 = getRandomPointInTriangle(triangle)
		points.append(point)
	
	return points


func getRandomTriangle(triangulation : Dictionary) -> Array:
	var chosen_weight : float = _rng.randf() * triangulation.area
	var current_weight : float = 0.0
	for triangle in triangulation.triangles:
		current_weight += triangle.area
		if current_weight > chosen_weight:
			return triangle.points
	return []


func getRandomPointInTriangle(triangle : Array) -> Vector2:
	var rand_one : float = _rng.randf()
	var rand_two : float = _rng.randf()
	var square_root_rand_one : float = sqrt(rand_one)
	
	return (1.0 - square_root_rand_one) * triangle[0] + square_root_rand_one * (1.0 - rand_two) * triangle[1] + square_root_rand_one * rand_two * triangle[2]



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		for source in _source_polygon_parent.get_children():
			if delauny_fractrue:
				fractureDelauny(source.polygon, source.global_position, cuts, min_area)
			else:
				if simple_fracture:
					fractureSimple(source.polygon, source.global_position, cuts, min_area)
				else:
					fracture(source.polygon, source.global_position, cuts, random_points, min_area)
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().reload_current_scene()



#func _draw() -> void:
#	var delauny : bool = true
#	if not delauny:
#		for source in _source_polygon_parent.get_children():
#			var triangulation : Dictionary = triangulatePolygon(source.polygon, true, true)
#			for triangle in triangulation.triangles:
#				draw_polygon(triangle.points, [Color(_rng.randf(), _rng.randf(), _rng.randf(), 1.0)])
#				draw_circle(triangle.centroid, 15.0, Color.white)
#	else:
#		for source in _source_polygon_parent.get_children():
#			var points = getRandomPointsInPolygon(source.polygon, 15)
#			var triangulation : Dictionary = triangulatePolygonDelauny(points + source.polygon, true, true)
#
#			var final_polygons : Array = []
#			for triangle in triangulation.triangles:
#				var result = Geometry.intersect_polygons_2d(triangle.points, source.polygon)
#				for r in result:
#					if r.size() > 0 and not Geometry.is_polygon_clockwise(r):
#						final_polygons.append(r)
#
#			for f in final_polygons:
#				draw_polygon(f, [Color(_rng.randf(), _rng.randf(), _rng.randf(), 1.0)])
#
#			return
#			for triangle in triangulation.triangles:
#				draw_polygon(triangle.points, [Color(_rng.randf(), _rng.randf(), _rng.randf(), 1.0)])
##				draw_circle(triangle.centroid, 15.0, Color.white)
#
#			for p in points + source.polygon:
#				draw_circle(p, 10.0, Color.white)
		
		
#	var points : Array = getRandomPointsInPolygon(getPolygon(), cuts)
#	for point in points:
#		draw_circle(point, 15.0, Color.orange)
#
#
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
#
#		var new_scale : float = 10.0
#		var offset : Vector2 = start
#
#		start -= offset
#		end -= offset
#
#		end *= new_scale
#
#		start += offset
#		end += offset
#
#		var new_v : Vector2 = start - end
#		start += new_v
#
#		draw_line(start, end, Color.green, 3.0, true)
	
	
	
#	var bounding_rect : Rect2 = getBoundingRect()
#
#
#	draw_rect(bounding_rect, Color.red, false, 5.0, true)
#	draw_circle(bounding_rect.position, 30.0, Color.yellow)
#	draw_circle(bounding_rect.end, 30.0, Color.orange)
#
#	var A : Vector2 = bounding_rect.position
#	var C : Vector2 = bounding_rect.end
#
#	var B : Vector2 = Vector2(C.x, A.y)
#	var D : Vector2 = Vector2(A.x, C.y)
#
#
#	draw_circle(A, 15.0, Color.blue)
#	draw_circle(B, 15.0, Color.blue)
#	draw_circle(C, 15.0, Color.blue)
#	draw_circle(D, 15.0, Color.blue)
#
#
#	var lines : Array = getCutLines(bounding_rect, cuts)
#
#	for line in lines:
#		draw_line(line.position, line.end, Color.green, 2.0, true)
#		var poly = Geometry.offset_polyline_2d(makeLine(line), 10)
#		draw_polygon(poly[0], [Color(1, 1, 1, 0.25)])
