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




export(Color) var fracture_body_color




var _cur_fracture_color : Color = fracture_body_color
var _input_disabled : bool = false



onready var rigidbody_template = preload("res://demo/src/RigidBody2D.tscn")
onready var polyFracture := PolygonFracture.new()
onready var _pool_fracture_shards := $Pool_FractureShards
onready var _pool_cut_visualizer := $Pool_CutVisualizer
onready var _source_polygon_parent := $SourceParent
onready var _rng := RandomNumberGenerator.new()




func _ready() -> void:
	_rng.randomize()
	
	var color := Color.white
	color.s = fracture_body_color.s
	color.v = fracture_body_color.v
	color.h = _rng.randf()
	_cur_fracture_color = color
	_source_polygon_parent.modulate = _cur_fracture_color




func _input(event: InputEvent) -> void:
	if _input_disabled: return
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == 1:
			simpleCut(get_global_mouse_position())




func simpleCut(pos : Vector2) -> void:
	if _input_disabled: return
	var cut_shape : PoolVector2Array = PolygonLib.createCirclePolygon(50.0, 1)
	cutSourcePolygons(pos, cut_shape, 0.0, _rng.randf_range(400.0, 800.0), 2.0)
	_input_disabled = true
	set_deferred("_input_disabled", false)


func cutSourcePolygons(cut_pos : Vector2, cut_shape : PoolVector2Array, cut_rot : float, cut_force : float = 0.0, fade_speed : float = 2.0) -> void:
	var instance = _pool_cut_visualizer.getInstance()
	instance.spawn(cut_pos, fade_speed)
	instance.setPolygon(cut_shape)
	
	for source in _source_polygon_parent.get_children():
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
		
		
		var cut_fracture_info : Dictionary = polyFracture.cutFracture(source_polygon, cut_shape, source_trans, cut_trans, 5000, 3000, 250, 1)
		
		if cut_fracture_info.shapes.size() <= 0 and cut_fracture_info.fractures.size() <= 0:
			continue
		
		for fracture in cut_fracture_info.fractures:
			for fracture_shard in fracture:
				var area_p : float = fracture_shard.area / total_area
				
				spawnFractureBody(fracture_shard, source.getTextureInfo(), s_mass * area_p)
		
		
		for shape in cut_fracture_info.shapes:
			var area_p : float = shape.area / total_area
			var mass : float = s_mass * area_p
			var dir : Vector2 = (shape.spawn_pos - cut_pos).normalized()
			
			call_deferred("spawnRigibody2d", shape, source.modulate, s_lin_vel + (dir * cut_force) / mass, s_ang_vel, mass, cut_pos, source.getTextureInfo())
		
		source.queue_free()


func spawnRigibody2d(shape_info : Dictionary, color : Color, lin_vel : Vector2, ang_vel : float, mass : float, cut_pos : Vector2, texture_info : Dictionary) -> void:
	var instance = rigidbody_template.instance()
	_source_polygon_parent.add_child(instance)
	instance.global_position = shape_info.spawn_pos
	instance.global_rotation = shape_info.spawn_rot
	instance.set_polygon(shape_info.centered_shape)
	instance.modulate = color
	instance.linear_velocity = lin_vel# + (spawn_pos - cut_pos).normalized() * 50
	instance.angular_velocity = ang_vel
	instance.mass = mass
	instance.setTexture(PolygonLib.setTextureOffset(texture_info, shape_info.centroid))


func spawnFractureBody(fracture_shard : Dictionary, texture_info : Dictionary, new_mass : float) -> void:
	var instance = _pool_fracture_shards.getInstance()
	if not instance:
		return
	
	#fracture shard variant
	var dir : Vector2 = (fracture_shard.spawn_pos - fracture_shard.source_global_trans.get_origin()).normalized()
	instance.spawn(fracture_shard.spawn_pos, fracture_shard.spawn_rot, fracture_shard.source_global_trans.get_scale(), _rng.randf_range(0.5, 2.0))
	instance.setPolygon(fracture_shard.centered_shape, _cur_fracture_color, PolygonLib.setTextureOffset(texture_info, fracture_shard.centroid))
	instance.setMass(new_mass)
	instance.addForce(dir * 500.0)
	instance.addTorque(_rng.randf_range(-2, 2))
	
	#fracture body variant
#	instance.spawn(fracture_shard.spawn_pos)
#	instance.global_rotation = fracture_shard.spawn_rot
#
#	if instance.has_method("setPolygon"):
#		var s : Vector2 = fracture_shard.source_global_trans.get_scale()
#		instance.setPolygon(fracture_shard.centered_shape, s)
#
#	instance.setColor(_cur_fracture_color)
#
#	var dir : Vector2 = (fracture_shard.spawn_pos - fracture_shard.source_global_trans.get_origin()).normalized()
#	instance.linear_velocity = dir * _rng.randf_range(300, 500)
#	instance.angular_velocity = _rng.randf_range(-1, 1)
#
#	instance.setTexture(PolygonLib.setTextureOffset(texture_info, fracture_shard.centroid))
