extends Node2D



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




const FLICK_MAX_VELOCITY : float = 2000.0
const FLICK_MIN_VELOCITY : float = 500.0
const FLICK_MAGNITUDE_SCALE_FACTOR : float = 3.0
const MAX_AMMO : int = 5




export(Color) var fracture_body_color
export(Color) var no_ammo_line_color




var _cur_fracture_color : Color = fracture_body_color
var _fracture_disabled : bool = false
var _flick_start_point := Vector2.ZERO
var _fracture_balls_count : int = 0




onready var rigidbody_template = preload("res://demo/src/RigidBody2D.tscn")
onready var polyFracture := PolygonFracture.new()

onready var _pool_fracture_shards := $Pool_FractureShards
onready var _pool_cut_visualizer := $Pool_CutVisualizer
onready var _pool_point_fracture_ball := $Pool_PointFractureBall

onready var _source_polygon_parent := $SourceParent
onready var _rng := RandomNumberGenerator.new()
onready var _flick_line := $FlickLine
onready var _flick_line_arrow := $FlickLine/Arrow
onready var _default_flick_line_color : Color = _flick_line.modulate




func _ready() -> void:
	_rng.randomize()
	
	var color := Color.white
	color.s = fracture_body_color.s
	color.v = fracture_body_color.v
	color.h = _rng.randf()
	_cur_fracture_color = color
	_source_polygon_parent.modulate = _cur_fracture_color
	
	_flick_line.points = [Vector2.ZERO, Vector2.ZERO]
	_flick_line.visible = false


func _process(delta: float) -> void:
	if _flick_line.visible:
		var end_point : Vector2 = get_global_mouse_position()
		var flick_vec : Vector2 = end_point - _flick_start_point
		
		var line_point : Vector2 = _flick_start_point + flick_vec.normalized() * min(flick_vec.length(), FLICK_MAX_VELOCITY / FLICK_MAGNITUDE_SCALE_FACTOR)
		
		_flick_line_arrow.global_rotation = flick_vec.normalized().angle() + PI
		
		_flick_line.set_point_position(1, line_point)
		
		if _fracture_balls_count >= MAX_AMMO:
			_flick_line.modulate = no_ammo_line_color
		else:
			_flick_line.modulate = _default_flick_line_color


func _input(event: InputEvent) -> void:
	if _fracture_disabled: return
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				_flick_start_point = get_global_mouse_position()
				_flick_line_arrow.global_position = _flick_start_point
				_flick_line.set_point_position(0, _flick_start_point)
				_flick_line.set_point_position(1, _flick_start_point)
				_flick_line.visible = true
			else:
				if _fracture_balls_count >= MAX_AMMO:
					_flick_line.visible = false
					return
				
				var flick_end_point : Vector2 = get_global_mouse_position()
				if flick_end_point == _flick_start_point:
					_flick_line.visible = false
					return
				
				var flick_vec : Vector2 = flick_end_point - _flick_start_point
				var instance = _pool_point_fracture_ball.getInstance()
				if not instance:
					return
				
				var launch_vec : Vector2 = -flick_vec.normalized()
				var launch_magnitude : float = clamp(flick_vec.length() * FLICK_MAGNITUDE_SCALE_FACTOR, FLICK_MIN_VELOCITY, FLICK_MAX_VELOCITY)
				var rand_lifetime : float = _rng.randf_range(5.0, 10.0)
				instance.spawn(_flick_start_point, launch_vec * launch_magnitude, rand_lifetime, self)
				
				_flick_line.visible = false
				
				fractureBallSpawned()




func cutSourcePolygons(source, cut_pos : Vector2, cut_shape : PoolVector2Array, cut_rot : float, cut_force : float = 0.0, fade_speed : float = 2.0) -> void:
	spawnVisualizer(cut_pos, cut_shape, fade_speed)
	
	var source_polygon : PoolVector2Array = source.get_polygon()
	var total_area : float = PolygonLib.getPolygonArea(source_polygon)
	
	var source_trans : Transform2D = source.get_global_transform()
	var cut_trans := Transform2D(cut_rot, cut_pos)
	
	var s_lin_vel := Vector2.ZERO
	var s_ang_vel : float = 0.0
	var s_mass : float = 0.0
	
	if source is RigidBody2D:
		s_lin_vel = source.linear_velocity
		s_ang_vel = source.angular_velocity
		s_mass = source.mass
	
	
	var cut_fracture_info : Dictionary = polyFracture.cutFracture(source_polygon, cut_shape, source_trans, cut_trans, 2500, 1500, 100, 1)
	
	if cut_fracture_info.shapes.size() <= 0 and cut_fracture_info.fractures.size() <= 0:
		return
	
	for fracture in cut_fracture_info.fractures:
		for fracture_shard in fracture:
			var area_p : float = fracture_shard.area / total_area
			var rand_lifetime : float = _rng.randf_range(1.0, 3.0) + 2.0 * area_p
			spawnFractureBody(fracture_shard, source.getTextureInfo(), s_mass * area_p, rand_lifetime)
	
	
	for shape in cut_fracture_info.shapes:
		var area_p : float = shape.area / total_area
		var mass : float = s_mass * area_p
		var dir : Vector2 = (shape.spawn_pos - cut_pos).normalized()
		
		call_deferred("spawnRigibody2d", shape, source.modulate, s_lin_vel + (dir * cut_force) / mass, s_ang_vel, mass, cut_pos, source.getTextureInfo())
		
	source.queue_free()


func fractureCollision(pos : Vector2, other_body, fracture_ball) -> void:
	if _fracture_disabled: return
	
	var p : float = fracture_ball.launch_velocity / FLICK_MAX_VELOCITY
	var cut_shape : PoolVector2Array = polyFracture.generateRandomPolygon(Vector2(25, 200) * p, Vector2(18,72), Vector2.ZERO)
	cutSourcePolygons(other_body, pos, cut_shape, 0.0, _rng.randf_range(400.0, 800.0), 2.0)
	
	_fracture_disabled = true
	set_deferred("_fracture_disabled", false)




func spawnRigibody2d(shape_info : Dictionary, color : Color, lin_vel : Vector2, ang_vel : float, mass : float, cut_pos : Vector2, texture_info : Dictionary) -> void:
	var instance = rigidbody_template.instance()
	_source_polygon_parent.add_child(instance)
	instance.global_position = shape_info.spawn_pos
	instance.global_rotation = shape_info.spawn_rot
	instance.set_polygon(shape_info.centered_shape)
	instance.modulate = color
	instance.linear_velocity = lin_vel
	instance.angular_velocity = ang_vel
	instance.mass = mass
	instance.setTexture(PolygonLib.setTextureOffset(texture_info, shape_info.centroid))


func spawnFractureBody(fracture_shard : Dictionary, texture_info : Dictionary, new_mass : float, life_time : float) -> void:
	var instance = _pool_fracture_shards.getInstance()
	if not instance:
		return
	
	var dir : Vector2 = (fracture_shard.spawn_pos - fracture_shard.source_global_trans.get_origin()).normalized()
	instance.spawn(fracture_shard.spawn_pos, fracture_shard.spawn_rot, fracture_shard.source_global_trans.get_scale(), life_time)
	instance.setPolygon(fracture_shard.centered_shape, _cur_fracture_color, PolygonLib.setTextureOffset(texture_info, fracture_shard.centroid))
	instance.setMass(new_mass)


func spawnVisualizer(pos : Vector2, poly : PoolVector2Array, fade_speed : float) -> void:
	var instance = _pool_cut_visualizer.getInstance()
	instance.spawn(pos, fade_speed)
	instance.setPolygon(poly)




func fractureBallDespawned(pos : Vector2, poly : PoolVector2Array) -> void:
	spawnVisualizer(pos, poly, 0.75)
	_fracture_balls_count -= 1


func fractureBallSpawned() -> void:
	_fracture_balls_count += 1

