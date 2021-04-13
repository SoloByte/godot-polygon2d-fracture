extends Node2D




# MIT License
# -----------------------------------------------------------------------
#                       This file is part of:                           
#                     GODOT Polygon 2D Fracture                         
#           https://github.com/SoloByte/godot-polygon2d-fracture          
# -----------------------------------------------------------------------
# Copyright (c) 2021 Dave Grueneis
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
