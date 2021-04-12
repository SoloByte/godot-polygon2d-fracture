extends Node2D




enum DELAUNY_TYPES {DEFAULT = 0, CONVEX = 1, RECTANGLE = 2}




export(Color) var fracture_body_color
export(PackedScene) var fracture_body_template




export(bool) var delauny_fracture = false
export(DELAUNY_TYPES) var delauny_type = DELAUNY_TYPES.DEFAULT

export(bool) var simple_fracture = true



onready var polyFracture := PolygonFracture.new()
onready var _source_polygon_parent := $SourcePolygons
onready var _parent := $Parent
onready var _visible_timer := $VisibleTimer
onready var _slowdown_timer := $SlowdownTimer
onready var _timer := $Timer

onready var _rng := RandomNumberGenerator.new()

onready var _fracture_slider := $CanvasLayer/FracturesSlider
onready var _fractures_label := $CanvasLayer/FracturesSlider/Label
onready var _min_area_slider := $CanvasLayer/MinAreaSlider
onready var _min_area_label := $CanvasLayer/MinAreaSlider/Label
onready var _pool_fracture_bodies := $Pool_FractureBodies



var _cur_fracture_color : Color = fracture_body_color
var _auto_active : bool = false
var cuts : int = 3 
var min_area : int = 25



func _ready() -> void:
	_rng.randomize()
	
	var color := Color.white
	color.s = fracture_body_color.s
	color.v = fracture_body_color.v
	color.h = _rng.randf()
	_cur_fracture_color = color
	_source_polygon_parent.modulate = _cur_fracture_color
	_fracture_slider.grab_focus()
	
	_fracture_slider.value = 16
	_min_area_slider.value = 2000
	_on_FracturesSlider_value_changed(16)
	_on_MinAreaSlider_value_changed(2000)



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fracture") and _source_polygon_parent.visible:
		fractureAll()
	
	if event.is_action_pressed("auto"):
		if _auto_active:
			_auto_active = false
			_timer.stop()
		else:
			_auto_active = true
			_timer.start(3.0)


#func _exit_tree() -> void:
#	_pool_fracture_bodies.clearPoolInstant()


func fractureAll() -> void:
	_visible_timer.start(2.0)
	_slowdown_timer.start(0.25)
	Engine.time_scale = 0.1
	_source_polygon_parent.visible = false
	
	for source in _source_polygon_parent.get_children():
		var fracture_info : Array
		
		if delauny_fracture:
			match delauny_type:
				DELAUNY_TYPES.DEFAULT:
					fracture_info = polyFracture.fractureDelaunay(source.polygon, source.get_global_transform(), cuts, min_area)
#					fracture_info = fractureDelauny(source.polygon, source.global_position, source.global_rotation, cuts, min_area)
				DELAUNY_TYPES.CONVEX:
					fracture_info = polyFracture.fractureDelaunayConvex(source.polygon, source.get_global_transform(), cuts, min_area)
#					fracture_info = fractureDelaunyConvex(source.polygon, source.global_position, source.global_rotation, cuts, min_area)
				DELAUNY_TYPES.RECTANGLE:
					fracture_info = polyFracture.fractureDelaunayRectangle(source.polygon, source.get_global_transform(), cuts, min_area)
#					fracture_info = fractureDelaunyRectangle(source.polygon, source.global_position, source.global_rotation, cuts, min_area)
		else:
			if simple_fracture:
				fracture_info = polyFracture.fractureSimple(source.polygon, source.get_global_transform(), cuts, min_area)
#				fracture_info = fractureSimple(source.polygon, source.global_position, source.global_rotation, cuts, min_area)
			else:
				fracture_info = polyFracture.fracture(source.polygon, source.get_global_transform(), cuts, min_area)
#				fracture_info = fracture(source.polygon, source.global_position, source.global_rotation, cuts, min_area)
		
		for entry in fracture_info:
			var texture_info : Dictionary = {"texture" : source.texture, "rot" : source.texture_rotation, "offset" : source.texture_offset, "scale" : source.texture_scale}
			spawnFractureBody(entry, texture_info)



func spawnFractureBody(fracture_shard : Dictionary, texture_info : Dictionary) -> void:
	var instance = _pool_fracture_bodies.getInstance()
	if not instance: 
		return
	
	
#	var dir : Vector2 = (fracture_shard.spawn_pos - fracture_shard.source_global_trans.get_origin()).normalized()
#	instance.spawn(fracture_shard.spawn_pos, fracture_shard.spawn_rot, fracture_shard.source_global_trans.get_scale(), _rng.randf_range(0.5, 2.0))
#	instance.setPolygon(fracture_shard.centered_shape, _cur_fracture_color, texture_info)
#	instance.addForce(dir * _rng.randf_range(250, 600))
#	instance.addTorque(_rng.randf_range(-2, 2))
	
	
	instance.spawn(fracture_shard.spawn_pos)
	instance.global_rotation = fracture_shard.spawn_rot
	if instance.has_method("setPolygon"):
		var s : Vector2 = fracture_shard.source_global_trans.get_scale()
		instance.setPolygon(fracture_shard.centered_shape, s)


	instance.setColor(_cur_fracture_color)
	var dir : Vector2 = (fracture_shard.spawn_pos - fracture_shard.source_global_trans.get_origin()).normalized()
	instance.linear_velocity = dir * _rng.randf_range(200, 400)
	instance.angular_velocity = _rng.randf_range(-1, 1)

	instance.setTexture(PolygonLib.setTextureOffset(texture_info, fracture_shard.centroid))




func _on_Timer_timeout() -> void:
	fractureAll()


func _on_VisibleTimer_timeout() -> void:
	var color := Color.white
	color.s = fracture_body_color.s
	color.v = fracture_body_color.v
	color.h = _rng.randf()
	_cur_fracture_color = color
	_source_polygon_parent.modulate = _cur_fracture_color
	_source_polygon_parent.visible = true


func _on_SlowdownTimer_timeout() -> void:
	Engine.time_scale = 1.0



func _on_FracturesSlider_value_changed(value: float) -> void:
	_fractures_label.text = "Fractures: %d" % value
	cuts = _fracture_slider.value


func _on_MinAreaSlider_value_changed(value):
	_min_area_label.text = "Min Area: %d" % value
	min_area = _min_area_slider.value




#original source code
#func fractureSimple(source_polygon : PoolVector2Array, world_pos : Vector2, world_rot_rad : float, cut_number : int, min_discard_area : float) -> Array:
#	cut_number = clamp(cut_number, 0, 32)
#	source_polygon = rotatePolygon(source_polygon, world_rot_rad)
#	var bounding_rect : Rect2 = getBoundingRect(source_polygon)
#	var cut_lines : Array = getCutLines(bounding_rect, cut_number)
#
#	var polygons : Array = [source_polygon]
#
#	for line in cut_lines:
#		var poly_line = Geometry.offset_polyline_2d(makeLine(line), 0.1)[0]
#		var new_polies : Array = []
#		for poly in polygons:
#			var result : Array = Geometry.clip_polygons_2d(poly, poly_line)
#			new_polies += result
#
#		polygons.clear()
#		polygons += new_polies
#
#	var fracture_info : Array = []
#	for poly in polygons:
#		if not Geometry.is_polygon_clockwise(poly):
#			var triangulation : Dictionary = triangulatePolygon(poly, true, true)
#
#			if triangulation.area > min_discard_area:
#				var entry : Dictionary = {"poly" : poly, "centroid" : getPolyCentroid(triangulation.triangles, triangulation.area), "world_pos" : world_pos}
#				fracture_info.append(entry)
##				spawnFractureBody(poly, getPolyCentroid(triangulation.triangles, triangulation.area), world_pos)
#
#	return fracture_info
#
#
#func fracture(source_polygon : PoolVector2Array, world_pos : Vector2, world_rot_rad : float, cut_number : int, min_discard_area : float) -> Array:
#	cut_number = clamp(cut_number, 0, 32)
#	source_polygon = rotatePolygon(source_polygon, world_rot_rad)
#	var bounding_rect : Rect2 = getBoundingRect(source_polygon)
#	var points : Array = getRandomPointsInPolygon(source_polygon, cut_number * 2)
#	var cut_lines : Array = getCutLinesFromPoints(points, cut_number, getBoundingRectMaxSize(bounding_rect))
#
#	var polygons : Array = [source_polygon]
#
#	for line in cut_lines:
#		var poly_line = Geometry.offset_polyline_2d(makeLine(line), 0.1)[0]
#		var new_polies : Array = []
#		for poly in polygons:
#			var result : Array = Geometry.clip_polygons_2d(poly, poly_line)
#			new_polies += result
#
#		polygons.clear()
#		polygons += new_polies
#
#	var fracture_info : Array = []
#	for poly in polygons:
#		if not Geometry.is_polygon_clockwise(poly):
#			var triangulation : Dictionary = triangulatePolygon(poly, true, true)
#
#			if triangulation.area > min_discard_area:
#				var entry : Dictionary = {"poly" : poly, "centroid" : getPolyCentroid(triangulation.triangles, triangulation.area), "world_pos" : world_pos}
#				fracture_info.append(entry)
##				spawnFractureBody(poly, getPolyCentroid(triangulation.triangles, triangulation.area), world_pos)
#
#	return fracture_info
#
#
#func fractureDelauny(source_polygon : PoolVector2Array, world_pos : Vector2, world_rot_rad : float, fracture_number : int, min_discard_area : float) -> Array:
#	source_polygon = rotatePolygon(source_polygon, world_rot_rad)
#	var points = getRandomPointsInPolygon(source_polygon, fracture_number)
#	var triangulation : Dictionary = triangulatePolygonDelauny(points + source_polygon, true, true)
#
#	var fracture_info : Array = []
#	for triangle in triangulation.triangles:
#		if triangle.area < min_discard_area:
#			continue
#
##		var is_inside_poly : bool = true
##		for p in triangle.points:
##			if not Geometry.is_point_in_polygon(p, source_polygon):
##				is_inside_poly = false
##				break
##
##		if is_inside_poly:
##			if not Geometry.is_point_in_polygon(getTriangleCentroid(triangle.points), source_polygon):
##				is_inside_poly = false
##
##
##		if is_inside_poly:
##			var entry : Dictionary = {"poly" : triangle.points, "centroid" : triangle.centroid, "world_pos" : world_pos}
##			fracture_info.append(entry)
###			spawnFractureBody(triangle.points, triangle.centroid, world_pos)
##		else:
#		var results : Array = Geometry.intersect_polygons_2d(triangle.points, source_polygon)
#		for r in results:
#			if r.size() > 0 and not Geometry.is_polygon_clockwise(r):
#				if r.size() == 3:
#					var area : float = getTriangleArea(r)
#					if area >= min_discard_area:
#						var entry : Dictionary = {"poly" : r, "centroid" : getTriangleCentroid(r), "world_pos" : world_pos}
#						fracture_info.append(entry)
#				else:
#					var t : Dictionary = triangulatePolygon(r, true, true)
#					if t.area >= min_discard_area:
#						var entry : Dictionary = {"poly" : r, "centroid" : getPolyCentroid(t.triangles, t.area), "world_pos" : world_pos}
#						fracture_info.append(entry)
#
#	return fracture_info
#
#
#func fractureDelaunyConvex(concave_polygon : PoolVector2Array, world_pos : Vector2, world_rot_rad : float, fracture_number : int, min_discard_area : float) -> Array:
#	concave_polygon = rotatePolygon(concave_polygon, world_rot_rad)
#	var points = getRandomPointsInPolygon(concave_polygon, fracture_number)
#	var triangulation : Dictionary = triangulatePolygonDelauny(points + concave_polygon, true, true)
#
#	var fracture_info : Array = []
#	for triangle in triangulation.triangles:
#		if triangle.area < min_discard_area:
#			continue
#
#		var entry : Dictionary = {"poly" : triangle.points, "centroid" : getTriangleCentroid(triangle.points), "world_pos" : world_pos}
#		fracture_info.append(entry)
#
#	return fracture_info
#
#
#func fractureDelaunyRectangle(rectangle_polygon : PoolVector2Array, world_pos : Vector2, world_rot_rad : float, fracture_number : int, min_discard_area : float) -> Array:
#	rectangle_polygon = rotatePolygon(rectangle_polygon, world_rot_rad)
#	var points = getRandomPointsInRectangle(getBoundingRect(rectangle_polygon), fracture_number)
#	var triangulation : Dictionary = triangulatePolygonDelauny(points + rectangle_polygon, true, true)
#
#	var fracture_info : Array = []
#	for triangle in triangulation.triangles:
#		if triangle.area < min_discard_area:
#			continue
#
#		var entry : Dictionary = {"poly" : triangle.points, "centroid" : getTriangleCentroid(triangle.points), "world_pos" : world_pos}
#		fracture_info.append(entry)
#
#	return fracture_info
#
#
#
#
#
#func triangulatePolygon(poly : PoolVector2Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
#	var total_area : float = 0.0
#	var triangle_points = Geometry.triangulate_polygon(poly)
#	var triangulation : Dictionary = {"triangles" : [], "area" : 0.0}
#	for i in range(triangle_points.size() / 3):
#		var index : int = i * 3
#		var points : Array = [poly[triangle_points[index]], poly[triangle_points[index + 1]], poly[triangle_points[index + 2]]]
#		var area : float = 0.0
#
#		if with_area:
#			area = getTriangleArea(points)
#		var centroid := Vector2.ZERO
#
#		if with_centroid:
#			centroid = getTriangleCentroid(points)
#
#		var triangle : Dictionary = {"points" : points, "area" : area, "centroid" : centroid}
#		total_area += area
#		triangulation.triangles.append(triangle)
#
#	triangulation.area = total_area
#	return triangulation
#
#
#func triangulatePolygonDelauny(poly : PoolVector2Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
#	var total_area : float = 0.0
#	var triangle_points = Geometry.triangulate_delaunay_2d(poly)
#	var triangulation : Dictionary = {"triangles" : [], "area" : 0.0}
#	for i in range(triangle_points.size() / 3):
#		var index : int = i * 3
#		var points : PoolVector2Array = [poly[triangle_points[index]], poly[triangle_points[index + 1]], poly[triangle_points[index + 2]]]
#		var area : float = 0.0
#
#		if with_area:
#			area = getTriangleArea(points)
#		var centroid := Vector2.ZERO
#
#		if with_centroid:
#			centroid = getTriangleCentroid(points)
#
#		var triangle : Dictionary = {"points" : points, "area" : area, "centroid" : centroid}
#		total_area += area
#		triangulation.triangles.append(triangle)
#
#	triangulation.area = total_area
#	return triangulation
#
#
#func getPolygonArea(poly : PoolVector2Array) -> float:
#	var triangulation : Dictionary = triangulatePolygon(poly, true, false)
#	return triangulation.area
#
#
#func getTriangleArea(points : PoolVector2Array) -> float:
#	var a : float = (points[1] - points[2]).length()
#	var b : float = (points[2] - points[0]).length()
#	var c : float = (points[0] - points[1]).length()
#	var s : float = (a + b + c) * 0.5
#
#	return sqrt(s * (s - a) * (s - b) * (s - c))
#
#
#func getTriangleCentroid(points : PoolVector2Array) -> Vector2:
#	var ab : Vector2 = points[1] - points[0]
#	var ac : Vector2 = points[2] - points[0]
#	var centroid : Vector2 = points[0] + (ab + ac) / 3.0
#	return centroid
#
#
#func getPolyCentroid(triangles : Array, total_area : float) -> Vector2:
#	var weighted_centroid := Vector2.ZERO
#	for triangle in triangles:
#		weighted_centroid += (triangle.centroid * triangle.area)
#	return weighted_centroid / total_area
#
#
#func getPolyVisualCenterPoint(poly : PoolVector2Array) -> Vector2:
#	var center_points : Array = []
#
#	for i in range(poly.size() - 1):
#		var p : Vector2 = lerp(poly[i], poly[i+1], 0.5)
#		center_points.append(p)
#
#	var total := Vector2.ZERO
#	for p in center_points:
#		total += p
#
#	total /= center_points.size()
#
#	return total
#
#
#func translatePolygon(poly : PoolVector2Array, offset : Vector2):
#	var new_poly : PoolVector2Array = []
#	for p in poly:
#		new_poly.append(p + offset)
#	return new_poly
#
#
#
#
#func getBoundingRectMaxSize(bounding_rect : Rect2) -> float:
#	var corners : Dictionary = getBoundingRectCorners(bounding_rect)
#
#	var AC : Vector2 = corners.C - corners.C
#	var BD : Vector2 = corners.D - corners.B
#
#	if AC.length_squared() > BD.length_squared():
#		return AC.length()
#	else:
#		return BD.length() 
#
#
#func getBoundingRectCorners(bounding_rect : Rect2) -> Dictionary:
#	var A : Vector2 = bounding_rect.position
#	var C : Vector2 = bounding_rect.end
#
#	var B : Vector2 = Vector2(C.x, A.y)
#	var D : Vector2 = Vector2(A.x, C.y)
#	return {"A" : A, "B" : B, "C" : C, "D" : D}
#
#
#func getCutLinesFromPoints(points : Array, cuts : int, max_size : float) -> Array:
#	var cut_lines : Array = []
#	if cuts <= 0 or not points or points.size() <= 2: return cut_lines
#
#	for i in range(cuts):
#		var start : Vector2 = points[(i * 2)]
#		var end : Vector2 = points[(i * 2) + 1]
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
#
#
#func makeLine(rect : Rect2) -> PoolVector2Array:
#	var line : PoolVector2Array = []
#	line.append(rect.position)
#	line.append(rect.end)
#	return line
#
#
#func getBoundingRect(poly : PoolVector2Array) -> Rect2:
#	var start := Vector2.ZERO
#	var end := Vector2.ZERO
#
#	for point in poly:
#		if point.x < start.x:
#			start.x = point.x
#		elif point.x > end.x:
#			end.x = point.x
#
#		if point.y < start.y:
#			start.y = point.y
#		elif point.y > end.y:
#			end.y = point.y
#
#	return Rect2(start, end - start)
#
#
#func getRandomPointsInRectangle(rectangle : Rect2, number : int) -> PoolVector2Array:
#	var points : PoolVector2Array = []
#
#	for i in range(number):
#		var x : float = _rng.randf_range(rectangle.position.x, rectangle.end.x)
#		var y : float = _rng.randf_range(rectangle.position.y, rectangle.end.y)
#		points.append(Vector2(x, y))
#
#	return points
#
#
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
#
#
#func rotatePolygon(poly : PoolVector2Array, rot : float):
#	var rotated_polygon : PoolVector2Array = []
#
#	for p in poly:
#		rotated_polygon.append(p.rotated(rot))
#
#	return rotated_polygon


#does not work 
#func isLongPolygon(poly : PoolVector2Array, threshold : float = 0.1) -> bool:
#	threshold = clamp(threshold, 0.0, 1.0)
#	var bounding_rect : Rect2 = getBoundingRect(poly)
#	if bounding_rect.size.x < bounding_rect.size.y:
#		var p : float = bounding_rect.size.x / bounding_rect.size.y
##		print("BR Size: ", bounding_rect.size, " - P: ", p)
#		return p < threshold
#	else:
#		var p : float = bounding_rect.size.y / bounding_rect.size.x
##		print("BR Size: ", bounding_rect.size, " - P: ", p)
#		return p < threshold



