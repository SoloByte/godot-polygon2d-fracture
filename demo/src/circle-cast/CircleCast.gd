extends Node2D
class_name CircleCast




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




export(float) var radius : float = 1.0
export(int, LAYERS_2D_PHYSICS) var collision_layer

export(int) var max_results : int = 6
export(float) var margin : float = 0.0

export(bool) var collide_with_bodies = true
export(bool) var collide_with_areas = false




var _query : Physics2DShapeQueryParameters = null
var _circle_shape : CircleShape2D = null
var _excluded : Array = []




func addExclusion(obj) -> void:
	_excluded.append(obj)

func removeExclusion(obj) -> void:
	if not _excluded or _excluded.size() <= 0: return
	var index : int = _excluded.find(obj)
	removeExclusionIndex(index)

func removeExclusionIndex(index : int) -> void:
	if not _excluded or _excluded.size() <= 0 or index < 0 or index >= _excluded.size(): return
	_excluded.remove(index)



func setCircleShapeRadius(r : float) -> void:
	if r <= 0.0: return
	getCircleShape().radius = r


func getCircleShape() -> CircleShape2D:
	if _circle_shape == null:
		_circle_shape = CircleShape2D.new()
		_circle_shape.radius = self.radius
	return _circle_shape


func getQuery() -> Physics2DShapeQueryParameters:
	if not _query:
		setQuery(createQuerySimple())
	return _query

func setQuery(query : Physics2DShapeQueryParameters) -> void:
	_query = query


func updateQuery(pos : Vector2, rot : float, r : float = -1.0) -> void:
	setCircleShapeRadius(r)
	updateCustomQuery(getQuery(), pos, rot, null)

func updateCustomQuery(query : Physics2DShapeQueryParameters, pos : Vector2, rot : float, shape = null) -> void:
	if not query: return
	query.transform = Transform2D(rot, pos)
	if shape:
		query.set_shape(shape)



func createQuerySimple() -> Physics2DShapeQueryParameters:
	return createQuery(global_position, global_rotation, Vector2.ZERO, getCircleShape(), collision_layer, _excluded, collide_with_bodies, collide_with_areas, margin)

func createQuery(_pos : Vector2, _rot : float, _motion : Vector2, _shape, _collision_layer, _exclude : Array = [], _collide_with_bodies : bool = true, _collide_with_areas : bool = false, _margin : float = 0.0) -> Physics2DShapeQueryParameters:
	var query := Physics2DShapeQueryParameters.new()
	query.set_shape(_shape)
	query.motion = _motion
	query.collision_layer = _collision_layer
	query.exclude = _exclude
	query.collide_with_bodies = _collide_with_bodies
	query.collide_with_areas = _collide_with_areas
	query.transform = Transform2D(_rot, _pos)
	query.margin = _margin
	return query


func getSpaceState() ->  Physics2DDirectSpaceState:
	return get_world_2d().direct_space_state




func cast(r : float = -1.0) -> Array:
	updateQuery(global_position, global_rotation, r)
	return intersectShape(getQuery(), max_results)

func castStatic(r : float = -1.0) -> Array:
	setCircleShapeRadius(r)
	return intersectShape(getQuery(), max_results)

func castCustom(_pos : Vector2, _rot : float, _shape, _collision_layer, _exclude : Array = [], _collide_with_bodies : bool = true, _collide_with_areas : bool = false, _margin : float = 0.0, max_results : int = 32) -> Array:
	var query = createQuery(_pos, _rot, Vector2.ZERO, _shape, _collision_layer, _exclude, _collide_with_bodies, _collide_with_areas, _margin)
	return intersectShape(query, max_results)


static func filterResults(result : Array) -> Array:
	print("results: ", result)
	if not result or result.size() <= 0:
		return []
	if result.size() == 1:
		return [result[0].collider]
	
	var filtered : Array = []
	for i in range(result.size()):
		var body = result[i].collider
		if not body in filtered:
			filtered.append(body)

	return filtered

static func filterResultsAdv(result : Array) -> Dictionary:
	if not result or result.size() <= 0:
		return {}
	
	var filtered : Dictionary = {}
	if result.size() == 1:
		filtered[result[0].collider_id] = {"body" : result[0].collider, "shapes" : [result[0].shape]}
		return filtered
	
	for r in result:
		if filtered.has(r.collider_id):
			filtered[r.collider_id].shapes.append(r.shape)
		else:
			filtered[r.collider_id] = {"body" : r.collider, "shapes" : [r.shape]}
	
	return filtered


func castMotion(query : Physics2DShapeQueryParameters) -> Array:
	return getSpaceState().cast_motion(query)


func getCollisionPoints(query : Physics2DShapeQueryParameters, max_results : int = 32) -> Array:
	return getSpaceState().collide_shape(query, max_results)


func castNearest(query : Physics2DShapeQueryParameters) -> Dictionary:
	# -!!!- This method does not take into account the motion property of the object.
	#collider_id: The colliding object's ID.
	#linear_velocity: The colliding object's velocity Vector2. If the object is an Area2D, the result is (0, 0).
	#metadata: The intersecting shape's metadata. This metadata is different from Object.get_meta(), and is set with Physics2DServer.shape_set_data().
	#normal: The object's surface normal at the intersection point.
	#point: The intersection point.
	#rid: The intersecting object's RID.
	#shape: The shape index of the colliding shape.
	return getSpaceState().get_rest_info(query)


func intersectPoint(_point : Vector2, _collision_layer : int, _max_results : int = 32, _exclude : Array = [], _collide_with_bodies : bool = true, _collide_with_areas : bool = false) -> Array:
	#collider: The colliding object.
	#collider_id: The colliding object's ID.
	#metadata: The intersecting shape's metadata. This metadata is different from Object.get_meta(), and is set with Physics2DServer.shape_set_data().
	#rid: The intersecting object's RID.
	#shape: The shape index of the colliding shape.
	# -!!!- ConcavePolygonShape2Ds and CollisionPolygon2Ds in Segments build mode are not solid shapes. Therefore, they will not be detected.
	return getSpaceState().intersect_point(_point, _max_results, _exclude, _collision_layer, _collide_with_bodies, _collide_with_areas)


func intersectShape(query : Physics2DShapeQueryParameters, max_results: int = 32) -> Array:
	# -!!!- This method does not take into account the motion property of the object.
	#collider: The colliding object.
	#collider_id: The colliding object's ID.
	#metadata: The intersecting shape's metadata. This metadata is different from Object.get_meta(), and is set with Physics2DServer.shape_set_data().
	#rid: The intersecting object's RID.
	#shape: The shape index of the colliding shape.
	
	#because of filtering only returns array of objects (no duplicate entries)
	return getSpaceState().intersect_shape(query, max_results)

































##public function for cast -> see pDoCast func for more information-------------------------------------------------------
##functions just differ in the parameters and what has to be set previously
##cast returns all objects inside the circle (motion vector is not used)
#func castSimple(pos : Vector2, exclude : Array = [], max_results : int = 6, margin : float = 0.0) -> Array:
#	return pDoCast(pos, collision_layer, exclude, max_results, collide_with_bodies, collide_with_areas, margin)
#
#func cast(pos : Vector2, radius : float, exclude : Array = [], max_results : int = 6, margin : float = 0.0) -> Array:
#	setRadius(radius)
#	return pDoCast(pos, collision_layer, exclude, max_results, collide_with_bodies, collide_with_areas, margin)
#
#
#func castQuery(pos : Vector2, rot : float, max_results : int = 6) -> Array:
#	if not _query: return []
#	var space_state = get_world_2d().direct_space_state
#	updateQuery(pos, rot)
#	return space_state.intersect_shape(_query, max_results)
#
#func castCustomQuery(query : Physics2DShapeQueryParameters, pos : Vector2, rot : float, max_results : int = 6) -> Array:
#	if not query: return []
#	var space_state = get_world_2d().direct_space_state
#	updateCustomQuery(query, pos, rot)
#	return space_state.intersect_shape(query, max_results)
##------------------------------------------------------------------------------------------------------------------------
#
#
#
#
##public function for castSingle -> see pDoCastSingle func for more information-------------------------------------------------------
##functions just differ in the parameters and what has to be set previously
##returns the first object it hits (motion vector is not used)
##returns a collision normal
#func castSingleSimple(pos : Vector2, exclude : Array = [], margin : float = 0.0) -> Dictionary:
#	return pDoCastSingle(pos, collision_layer, exclude, collide_with_bodies, collide_with_areas, margin)
#
#func castSingle(pos : Vector2, radius : float, exclude : Array = [], margin : float = 0.0) -> Dictionary:
#	setRadius(radius)
#	return pDoCastSingle(pos, collision_layer, exclude, collide_with_bodies, collide_with_areas, margin)
#
#func castSingleQuery(pos : Vector2) -> Dictionary:
#	if !_query: return {}
#	var space_state = get_world_2d().direct_space_state
#	updateQueryPos(pos)
#	return space_state.get_rest_info(_query)
#
#func castSingleCustomQuery(query : Physics2DShapeQueryParameters, pos : Vector2) -> Dictionary:
#	if !query: return {}
#	var space_state = get_world_2d().direct_space_state
#	updateCustomQueryPos(query, pos)
#	return space_state.get_rest_info(query)
##------------------------------------------------------------------------------------------------------------------------
#
#
#
#
##public function for castMotion -> see pDoCastMotion func for more information-------------------------------------------------------
##functions just differ in the parameters and what has to be set previously
##casts along the given motion vector (does not return collision info, just motion factors)
#func castMotionSimple(motion : Vector2, pos : Vector2, exclude : Array = [], margin : float = 0.0) -> Array:
#	return pDoCastMotion(motion, pos, collision_layer, exclude, collide_with_bodies, collide_with_areas, margin)
#
#func castMotion(motion : Vector2, pos : Vector2, radius : float, exclude : Array = [], margin : float = 0.0) -> Array:
#	setRadius(radius)
#	return pDoCastMotion(motion, pos, collision_layer, exclude, collide_with_bodies, collide_with_areas, margin)
#
#func castMotionQuery(motion : Vector2, pos : Vector2) -> Array:
#	if !_query: return []
#	var space_state = get_world_2d().direct_space_state
#	updateQueryMotion(motion)
#	updateQueryPos(pos)
#	return space_state.cast_motion(_query)
#
#func castMotionCustomQuery(query : Physics2DShapeQueryParameters, motion : Vector2, pos : Vector2) -> Array:
#	if !query: return []
#	var space_state = get_world_2d().direct_space_state
#	updateCustomQueryMotion(query, motion)
#	updateCustomQueryPos(query, pos)
#	return space_state.cast_motion(_query)
##------------------------------------------------------------------------------------------------------------------------
#
#
#
#
##public function for castCollision -> see pDoCastCollision func for more information-------------------------------------------------------
##functions just differ in the parameters and what has to be set previously
##just returns collision points (no further collision info)
#func castCollisionSimple(pos : Vector2, exclude : Array = [], max_results : int = 6, margin : float = 0.0) -> Array:
#	return pDoCastCollision(pos, collision_layer, exclude, max_results, collide_with_bodies, collide_with_areas, margin)
#
#func castCollision(pos : Vector2, radius : float, exclude : Array = [], max_results : int = 6, margin : float = 0.0) -> Array:
#	setRadius(radius)
#	return pDoCastCollision(pos, collision_layer, exclude, max_results, collide_with_bodies, collide_with_areas, margin)
#
#func castCollisionQuery(pos : Vector2,max_results : int = 6) -> Array:
#	if !_query: return []
#	var space_state = get_world_2d().direct_space_state
#	updateQueryPos(pos)
#	return space_state.collide_shape(_query, max_results)
#
#func castCollisionCustomQuery(query : Physics2DShapeQueryParameters, pos : Vector2, max_results : int = 6) -> Array:
#	if !query: return []
#	var space_state = get_world_2d().direct_space_state
#	updateCustomQueryPos(query, pos)
#	return space_state.collide_shape(_query, max_results)
##------------------------------------------------------------------------------------------------------------------------
#
#
#
#
##public function for castSingle -> see pDoCastSingle func for more information-------------------------------------------------------
##functions just differ in the parameters and what has to be set previously
##Checks whether a point is inside any shape.
#func intersectPoint(point: Vector2, exclude: Array = [], max_results: int = 6) -> Array:
#	#The shapes the point is inside of are returned in an array containing dictionaries with the following fields:
#		#collider: The colliding object.
#		#collider_id: The colliding object's ID.
#		#metadata: The intersecting shape's metadata. This metadata is different from Object.get_meta(), and is set with Physics2DServer.shape_set_data().
#		#rid: The intersecting object's RID.
#		#shape: The shape index of the colliding shape.
#	var space_state = get_world_2d().direct_space_state
#	return space_state.intersect_point(point, max_results, exclude, collision_layer, collide_with_bodies, collide_with_areas)
##------------------------------------------------------------------------------------------------------------------------
#
#
#
#
#
##private funcs for doing the casting based on the parameters------------------------------------------------------------
#func pDoCast(_pos : Vector2, _collision_layer, _exclude : Array = [], _max_results : int = 6, _collide_with_bodies : bool = true, _collide_with_areas : bool = false, _margin : float = 0.0) -> Array:
#	#returns array of dictionaries
#	#collider: The colliding object.
#	#collider_id: The colliding object's ID.
#	#metadata: The intersecting shape's metadata. This metadata is different from Object.get_meta(), and is set with Physics2DServer.shape_set_data().
#	#rid: The intersecting object's RID.
#	#shape: The shape index of the colliding shape.
#
#	var space_state = get_world_2d().direct_space_state
#	var query := createQuery(_pos, Vector2.ZERO, _collision_layer, _exclude, _collide_with_bodies, _collide_with_areas, _margin)
#	return space_state.intersect_shape(query, _max_results)
#
#
#func pDoCastSingle(_pos : Vector2, _collision_layer, _exclude : Array = [], _collide_with_bodies : bool = true, _collide_with_areas : bool = false, _margin : float = 0.0) -> Dictionary:
#	#returns dictionary
#	#collider_id: The colliding object's ID.
#	#linear_velocity: The colliding object's velocity Vector2. If the object is an Area2D, the result is (0, 0).
#	#metadata: The intersecting shape's metadata. This metadata is different from Object.get_meta(), and is set with Physics2DServer.shape_set_data().
#	#normal: The object's surface normal at the intersection point.
#	#point: The intersection point.
#	#rid: The intersecting object's RID.
#	#shape: The shape index of the colliding shape.
#	var space_state = get_world_2d().direct_space_state
#	var query := createQuery(_pos, Vector2.ZERO, _collision_layer, _exclude, _collide_with_bodies, _collide_with_areas, _margin)
#	return space_state.get_rest_info(query)
#
#
#func pDoCastMotion(_motion : Vector2, _pos : Vector2, _collision_layer, _exclude : Array = [], _collide_with_bodies : bool = true, _collide_with_areas : bool = false, _margin : float = 0.0) -> Array:
#	# The method will return an array with two floats between 0 and 1, 
#	#both representing a fraction of motion. 
#	#The first is how far the shape can move without triggering a collision, 
#	#and the second is the point at which a collision will occur. 
#	#If no collision is detected, the returned array will be [1, 1].
#	var space_state = get_world_2d().direct_space_state
#	var query := createQuery(_pos, _motion, _collision_layer, _exclude, _collide_with_bodies, _collide_with_areas, _margin)
#	return space_state.cast_motion(query)
#
#
#func pDoCastCollision(_pos : Vector2, _collision_layer, _exclude : Array = [], _max_results : int = 6, _collide_with_bodies : bool = true, _collide_with_areas : bool = false, _margin : float = 0.0) -> Array:
#	# The resulting array contains a list of points where the shape intersects another. 
#	#Like with intersect_shape(), the number of returned results can be limited to save processing time.
#	var space_state = get_world_2d().direct_space_state
#	var query := createQuery(_pos, Vector2.ZERO, _collision_layer, _exclude, _collide_with_bodies, _collide_with_areas, _margin)
#	return space_state.collide_shape(query, _max_results)
##------------------------------------------------------------------------------------------------------------------------






































