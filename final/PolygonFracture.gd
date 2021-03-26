class_name PolygonFracture





var _rng : RandomNumberGenerator


func _init(new_seed : int = -1) -> void:
	_rng = RandomNumberGenerator.new()
	
	if new_seed == -1:
		_rng.randomize()
	else:
		_rng.seed = new_seed




func makeFractureShard(poly : PoolVector2Array, centroid : Vector2, world_pos : Vector2, area : float) -> Dictionary:
	return {"poly" : poly, "centroid" : centroid, "world_pos" : world_pos, "area" : area}



#calculates the correct position for the instance
#translates the polygon to center it on the instance (centroid of the polygon)
#adds the instance as child of the parent
#if the instance has the method "setPolygon" the method will be used
#returns a dictionary with the instance and translated polygon
func spawnFractureBody(_parent, template : PackedScene, fracture_shard : Dictionary) -> Dictionary:
	var instance = template.instance()
	_parent.add_child(instance)
	instance.global_position = _parent.to_global(fracture_shard.centroid) + fracture_shard.world_pos
	var poly : PoolVector2Array = PolygonLib.translatePolygon(fracture_shard.poly, -fracture_shard.centroid)
	
	if instance.has_method("setPolygon"):
		instance.setPolygon(poly)
	
	return {"instance" : instance, "poly" : poly}




#all fracture functions return an array of dictionaries -> where the dictionary is 1 fracture shard (see func makeFractureShard) ------------------------------------------------------
func fractureSimple(source_polygon : PoolVector2Array, world_pos : Vector2, world_rot_rad : float, cut_number : int, min_discard_area : float) -> Array:
	cut_number = clamp(cut_number, 0, 32)
	source_polygon = PolygonLib.rotatePolygon(source_polygon, world_rot_rad)
	var bounding_rect : Rect2 = PolygonLib.getBoundingRect(source_polygon)
	var cut_lines : Array = getCutLines(bounding_rect, cut_number)
	
	var polygons : Array = [source_polygon]
	
	for line in cut_lines:
		var poly_line = PolygonLib.offsetPolyline(line, 0.1, true)[0]
		var new_polies : Array = []
		for poly in polygons:
			var result : Array = PolygonLib.clipPolygons(poly, poly_line, true)
			new_polies += result
		
		polygons.clear()
		polygons += new_polies
	
	var fracture_info : Array = []
	for poly in polygons:
		var triangulation : Dictionary = PolygonLib.triangulatePolygon(poly, true, true)
		
		if triangulation.area > min_discard_area:
			fracture_info.append(makeFractureShard(poly, PolygonLib.getPolygonCentroid(triangulation.triangles, triangulation.area), world_pos, triangulation.area))
	
	return fracture_info


func fracture(source_polygon : PoolVector2Array, world_pos : Vector2, world_rot_rad : float, cut_number : int, min_discard_area : float) -> Array:
	cut_number = clamp(cut_number, 0, 32)
	source_polygon = PolygonLib.rotatePolygon(source_polygon, world_rot_rad)
	var bounding_rect : Rect2 = PolygonLib.getBoundingRect(source_polygon)
	var points : Array = getRandomPointsInPolygon(source_polygon, cut_number * 2)
	var cut_lines : Array = getCutLinesFromPoints(points, cut_number, PolygonLib.getBoundingRectMaxSize(bounding_rect))
	
	var polygons : Array = [source_polygon]
	
	for line in cut_lines:
		var poly_line = PolygonLib.offsetPolyline(line, 0.1, true)[0]
		var new_polies : Array = []
		for poly in polygons:
			var result : Array = PolygonLib.clipPolygons(poly, poly_line, true)
			new_polies += result
		
		polygons.clear()
		polygons += new_polies
	
	var fracture_info : Array = []
	for poly in polygons:
		var triangulation : Dictionary = PolygonLib.triangulatePolygon(poly, true, true)
		
		if triangulation.area > min_discard_area:
			fracture_info.append(makeFractureShard(poly, PolygonLib.getPolygonCentroid(triangulation.triangles, triangulation.area), world_pos, triangulation.area))
	
	return fracture_info


func fractureDelaunay(source_polygon : PoolVector2Array, world_pos : Vector2, world_rot_rad : float, fracture_number : int, min_discard_area : float) -> Array:
	source_polygon = PolygonLib.rotatePolygon(source_polygon, world_rot_rad)
	var points = getRandomPointsInPolygon(source_polygon, fracture_number)
	var triangulation : Dictionary = PolygonLib.triangulatePolygonDelaunay(points + source_polygon, true, true)
	
	var fracture_info : Array = []
	for triangle in triangulation.triangles:
		if triangle.area < min_discard_area:
			continue
		
		var results : Array = PolygonLib.intersectPolygons(triangle.points, source_polygon, true)
		for r in results:
			if r.size() > 0:
				if r.size() == 3:
					var area : float = PolygonLib.getTriangleArea(r)
					if area >= min_discard_area:
						fracture_info.append(makeFractureShard(r, PolygonLib.getTriangleCentroid(r), world_pos, area))
				else:
					var t : Dictionary = PolygonLib.triangulatePolygon(r, true, true)
					if t.area >= min_discard_area:
						fracture_info.append(makeFractureShard(r, PolygonLib.getPolygonCentroid(t.triangles, t.area), world_pos, t.area))
	
	return fracture_info


func fractureDelaunayConvex(concave_polygon : PoolVector2Array, world_pos : Vector2, world_rot_rad : float, fracture_number : int, min_discard_area : float) -> Array:
	concave_polygon = PolygonLib.rotatePolygon(concave_polygon, world_rot_rad)
	var points = getRandomPointsInPolygon(concave_polygon, fracture_number)
	var triangulation : Dictionary = PolygonLib.triangulatePolygonDelaunay(points + concave_polygon, true, true)
	
	var fracture_info : Array = []
	for triangle in triangulation.triangles:
		if triangle.area < min_discard_area:
			continue
		
		fracture_info.append(makeFractureShard(triangle.points, PolygonLib.getTriangleCentroid(triangle.points), world_pos, triangle.area))
	
	return fracture_info


func fractureDelaunayRectangle(rectangle_polygon : PoolVector2Array, world_pos : Vector2, world_rot_rad : float, fracture_number : int, min_discard_area : float) -> Array:
	rectangle_polygon = PolygonLib.rotatePolygon(rectangle_polygon, world_rot_rad)
	var points = getRandomPointsInRectangle(PolygonLib.getBoundingRect(rectangle_polygon), fracture_number)
	var triangulation : Dictionary = PolygonLib.triangulatePolygonDelaunay(points + rectangle_polygon, true, true)
	
	var fracture_info : Array = []
	for triangle in triangulation.triangles:
		if triangle.area < min_discard_area:
			continue
		
		fracture_info.append(makeFractureShard(triangle.points, PolygonLib.getTriangleCentroid(triangle.points), world_pos, triangle.area))
	
	return fracture_info
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




func getCutLinesFromPoints(points : Array, cuts : int, max_size : float) -> Array:
	var cut_lines : Array = []
	if cuts <= 0 or not points or points.size() <= 2: return cut_lines
	
	for i in range(cuts):
		var start : Vector2 = points[(i * 2)]
		var end : Vector2 = points[(i * 2) + 1]
		var dir : Vector2 = (end - start).normalized()
		
		#extend the line so it will always be bigger than the polygon
		start -= dir * max_size
		end += dir * max_size
		
		var line : PoolVector2Array = [start, end]
		cut_lines.append(line)
	return cut_lines


func getCutLines(bounding_rect : Rect2, number : int) -> Array:
	var corners : Dictionary = PolygonLib.getBoundingRectCorners(bounding_rect)
	
	var horizontal_pair : Dictionary = {"left" : [corners.A, corners.D], "right" : [corners.B, corners.C]}
	var vertical_pair : Dictionary = {"top" : [corners.A, corners.B], "bottom" : [corners.D, corners.C]}
	
	var lines : Array = []
	for i in range(number):
		
		if _rng.randf() < 0.5:#horizontal
			var start : Vector2 = lerp(horizontal_pair.left[0], horizontal_pair.left[1], _rng.randf())
			var end : Vector2 = lerp(horizontal_pair.right[0], horizontal_pair.right[1], _rng.randf())
			var line : PoolVector2Array = [start, end]
			lines.append(line)
		else:#vertical
			var start : Vector2 = lerp(vertical_pair.top[0], vertical_pair.top[1], _rng.randf())
			var end : Vector2 = lerp(vertical_pair.bottom[0], vertical_pair.bottom[1], _rng.randf())
			var line : PoolVector2Array = [start, end]
			lines.append(line)
	
	return lines





func getRandomPointsInRectangle(rectangle : Rect2, number : int) -> PoolVector2Array:
	var points : PoolVector2Array = []
	
	for i in range(number):
		var x : float = _rng.randf_range(rectangle.position.x, rectangle.end.x)
		var y : float = _rng.randf_range(rectangle.position.y, rectangle.end.y)
		points.append(Vector2(x, y))
	
	return points


func getRandomPointsInPolygon(poly : PoolVector2Array, number : int) -> PoolVector2Array:
	var triangulation : Dictionary = PolygonLib.triangulatePolygon(poly, true, false)
	
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


func getRandomPointInTriangle(points : PoolVector2Array) -> Vector2:
	var rand_1 : float = _rng.randf()
	var rand_2 : float = _rng.randf()
	var sqrt_1 : float = sqrt(rand_1)
	
	return (1.0 - sqrt_1) * points[0] + sqrt_1 * (1.0 - rand_2) * points[1] + sqrt_1 * rand_2 * points[2]
